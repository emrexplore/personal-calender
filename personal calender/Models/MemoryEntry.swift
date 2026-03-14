import Foundation

struct MemoryEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var date: Date
    
    // Uygulama içi veritabanında saklanan resimlerin veya videoların dosya yolları
    var mediaPaths: [String] = []
    
    // Uygulama içi veritabanında saklanan sesli notun dosya yolu
    var audioPath: String?
    
    var isMilestone: Bool = false
    var milestoneType: MilestoneType?
    
    enum MilestoneType: String, Codable {
        case firstStep = "İlk Adım"
        case firstWord = "İlk Kelime"
        case firstTooth = "İlk Diş"
        case sitting = "Oturmaya Başladı"
        case solidFood = "Katı Gıdaya Geçiş"
        case other = "Diğer"
    }
}
