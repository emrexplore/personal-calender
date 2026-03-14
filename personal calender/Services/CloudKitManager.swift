import Foundation
import CloudKit

class CloudKitManager {
    static let shared = CloudKitManager()
    
    private let container = CKContainer.default()
    private let privateDatabase = CKContainer.default().privateCloudDatabase
    
    // Basit bir CloudKit entegrasyonu: JSON datalarını tek bir CloudKit Record (Backup) içinde tutarak yedekleme
    private let recordType = "AppBackup"
    private let recordID = CKRecord.ID(recordName: "mainBackupRecord")
    
    func backupDataToCloud(completion: @escaping (Bool) -> Void) {
        // Profilleri Oku
        let profiles = StorageManager.shared.loadProfiles()
        var backupDict: [String: Data] = [:]
        
        if let profilesData = try? JSONEncoder().encode(profiles) {
            backupDict["profiles"] = profilesData
        }
        
        // Her profilin Timeline'ını okuyup kaydet
        for profile in profiles {
            if let periods = StorageManager.shared.loadPeriods(for: profile.id),
               let periodsData = try? JSONEncoder().encode(periods) {
                backupDict["timeline_\(profile.id.uuidString)"] = periodsData
            }
        }
        
        // Yeni bir Record oluştur veya var olanı güncelle
        privateDatabase.fetch(withRecordID: recordID) { [weak self] existingRecord, error in
            guard let self = self else { return }
            
            let recordToSave: CKRecord
            if let record = existingRecord {
                recordToSave = record
            } else {
                recordToSave = CKRecord(recordType: self.recordType, recordID: self.recordID)
            }
            
            // Tüm verileri JSON String (Veya Data) olarak CKRecord içine göm
            for (key, value) in backupDict {
                recordToSave[key] = value as CKRecordValue
            }
            
            // Buluta gönder
            self.privateDatabase.save(recordToSave) { _, saveError in
                DispatchQueue.main.async {
                    if let err = saveError {
                        print("CloudKit Yedekleme Hatası: \(err.localizedDescription)")
                        completion(false)
                    } else {
                        print("CloudKit Yedekleme Başarılı!")
                        completion(true)
                    }
                }
            }
        }
    }
    
    func restoreDataFromCloud(completion: @escaping (Bool) -> Void) {
        privateDatabase.fetch(withRecordID: recordID) { record, error in
            guard let record = record, error == nil else {
                DispatchQueue.main.async {
                    print("CloudKit Geri Yükleme Hatası veya Kayıt Yok: \(error?.localizedDescription ?? "")")
                    completion(false)
                }
                return
            }
            
            // Profilleri al ve diske yaz
            if let profilesData = record["profiles"] as? Data,
               let profiles = try? JSONDecoder().decode([ChildProfile].self, from: profilesData) {
                StorageManager.shared.saveProfiles(profiles)
                
                // Timeline'ları al ve diske yaz
                for profile in profiles {
                    let key = "timeline_\(profile.id.uuidString)"
                    if let periodsData = record[key] as? Data,
                       let periods = try? JSONDecoder().decode([TimelinePeriod].self, from: periodsData) {
                        StorageManager.shared.savePeriods(periods, for: profile.id)
                    }
                }
                
                DispatchQueue.main.async {
                    print("CloudKit Geri Yükleme Başarılı!")
                    completion(true)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
}
