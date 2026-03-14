import Foundation

class StorageManager {
    static let shared = StorageManager()
    
    private let profileKey = "savedChildProfiles"
    private let oldProfileKey = "savedChildProfile" // Geriye dönük uyumluluk
    private let selectedProfileKey = "selectedChildProfileID"
    private let imagesDirectoryName = "MemoryImages"
    
    // MARK: - Multiple Profiles
    func saveProfiles(_ profiles: [ChildProfile]) {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }
    
    // Tekil ekleme / güncelleme (Mevcut kodları bozmamak için sarıcı)
    func saveProfile(_ profile: ChildProfile) {
        var allProfiles = loadProfiles()
        if let index = allProfiles.firstIndex(where: { $0.id == profile.id }) {
            allProfiles[index] = profile
        } else {
            allProfiles.append(profile)
        }
        saveProfiles(allProfiles)
        saveSelectedProfileID(profile.id) // En son eklenen/değişen aktif kalsın
    }
    
    // Profili sil ve ilişkili timeline dosyasını temizle
    func deleteProfile(_ id: UUID) {
        var allProfiles = loadProfiles()
        allProfiles.removeAll(where: { $0.id == id })
        saveProfiles(allProfiles)
        
        // ÖZEL: Önce profilin timeline içindeki bütün medya dosyalarını bellekten temizle
        if let periods = loadPeriods(for: id) {
            for period in periods {
                for entry in period.entries {
                    // Entry içerisindeki resim/videoları sil
                    for path in entry.mediaPaths {
                        deleteMedia(fileName: path)
                    }
                    
                    // Entry içerisindeki ses kayıtlarını sil
                    if let audioPath = entry.audioPath {
                        deleteAudio(fileName: audioPath)
                    }
                }
            }
        }
        
        let fileName = "timeline_\(id.uuidString).json"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        
        // Eğer silinen seçiliyse, seçili ID'yi temizle veya ilkini seç
        if loadSelectedProfileID() == id {
            if let first = allProfiles.first {
                saveSelectedProfileID(first.id)
            } else {
                UserDefaults.standard.removeObject(forKey: selectedProfileKey)
            }
        }
    }
    
    func loadProfiles() -> [ChildProfile] {
        // Yeni dizi sisteminden oku
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profiles = try? JSONDecoder().decode([ChildProfile].self, from: data) {
            return profiles
        }
        
        // Eskiden kalma tekil profil varsa onu diziye çevirip aktar
        if let oldData = UserDefaults.standard.data(forKey: oldProfileKey),
           let oldProfile = try? JSONDecoder().decode(ChildProfile.self, from: oldData) {
            let migrated = [oldProfile]
            saveProfiles(migrated)
            UserDefaults.standard.removeObject(forKey: oldProfileKey)
            return migrated
        }
        
        return []
    }
    
    // Uygulama açılışında en son seçili çocuğu döndürmek için
    func loadProfile() -> ChildProfile? {
        let all = loadProfiles()
        if let selectedID = loadSelectedProfileID(), let match = all.first(where: { $0.id == selectedID }) {
            return match
        }
        return all.first
    }
    
    func saveSelectedProfileID(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: selectedProfileKey)
    }
    
    func loadSelectedProfileID() -> UUID? {
        if let idString = UserDefaults.standard.string(forKey: selectedProfileKey),
           let uuid = UUID(uuidString: idString) {
            return uuid
        }
        return nil
    }
    
    // MARK: - Timeline Periods (Per Child)
    func savePeriods(_ periods: [TimelinePeriod], for childID: UUID) {
        let fileName = "timeline_\(childID.uuidString).json"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        if let data = try? JSONEncoder().encode(periods) {
            try? data.write(to: url)
        }
    }
    
    func loadPeriods(for childID: UUID) -> [TimelinePeriod]? {
        let fileName = "timeline_\(childID.uuidString).json"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        
        // Önce yeni spesifik dosyayı aramaya çalış
        if let data = try? Data(contentsOf: url),
           let periods = try? JSONDecoder().decode([TimelinePeriod].self, from: data) {
            return periods
        }
        
        // Eğer geriye dönük uyumluluk gerekiyorsa eski "timeline_periods.json" dosyasını oku ve yeniye kopyala
        let oldUrl = getDocumentsDirectory().appendingPathComponent("timeline_periods.json")
        if let data = try? Data(contentsOf: oldUrl),
           let periods = try? JSONDecoder().decode([TimelinePeriod].self, from: data) {
            // Eski olanı yeni isme kaydet, sonrakilerde hızlı açılır
            savePeriods(periods, for: childID)
            return periods
        }
        
        return nil
    }
    
    // MARK: - Audio Persistence
    func saveAudio(data: Data) -> String? {
        let directoryURL = getDocumentsDirectory().appendingPathComponent(imagesDirectoryName) // Resim the aynı klasörü kullanabilir, isim kargaşadan kurtarır veya Audiolar için ayrı klasör açılabilir.
        
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        
        let fileName = UUID().uuidString + ".m4a"
        let fileURL = directoryURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Ses kaydedilemedi: \(error)")
            return nil
        }
    }
    
    func loadAudioURL(fileName: String) -> URL? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(imagesDirectoryName).appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    // Growth Data Persistence
    // Not: Artık büyüme verileri (GrowthData) TimelinePeriod içerisine kaydediliyor.
    // Başlı başına growth_data.json kullanılmıyor.
    func saveMedia(data: Data, isVideo: Bool = false) -> String? {
        let directoryURL = getDocumentsDirectory().appendingPathComponent(imagesDirectoryName)
        
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        
        let ext = isVideo ? ".mp4" : ".jpg"
        let fileName = UUID().uuidString + ext
        let fileURL = directoryURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Medya kaydedilemedi: \(error)")
            return nil
        }
    }
    
    func loadImage(fileName: String) -> Data? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(imagesDirectoryName).appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }
    
    func deleteMedia(fileName: String) {
        let fileURL = getDocumentsDirectory().appendingPathComponent(imagesDirectoryName).appendingPathComponent(fileName)
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("Fiziksel dosya silindi: \(fileName)")
            }
        } catch {
            print("Dosya silinemedi: \(error)")
        }
    }
    
    func deleteAudio(fileName: String) {
        deleteMedia(fileName: fileName) // Aynı klasörde oldukları için medya silme ile ayını işlemi yapar.
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
