import Foundation

struct TimelinePeriod: Identifiable, Codable {
    var id: UUID = UUID()
    let type: PeriodType
    let number: Int
    let startDate: Date
    let endDate: Date
    
    var entries: [MemoryEntry] = []
    var growthData: [GrowthData] = []
    
    // YUI gruplaması için eklendi
    var customTitle: String?
    var children: [TimelinePeriod]?
    
    var title: String {
        if let customTitle = customTitle {
            return customTitle
        }
        
        switch type {
        case .week:
            return "\(number). Hafta"
        case .month:
            return "\(number). Ay"
        case .year:
            return "\(number). Yaş"
        }
    }
    
    enum PeriodType: String, Codable {
        case week
        case month
        case year
    }
}
