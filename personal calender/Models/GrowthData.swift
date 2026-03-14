import Foundation

struct GrowthData: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var height: Double? // cm cinsinden
    var weight: Double? // kg cinsinden
    var headCircumference: Double? // cm cinsinden
    
    var notes: String?
}
