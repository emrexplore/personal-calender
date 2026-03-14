import Foundation

struct TimelinePeriod: Identifiable, Codable {
    var id: UUID = UUID()
    var type: PeriodType
    let number: Int
    var startDate: Date
    var endDate: Date
    var customTitle: String?
    var children: [TimelinePeriod]?
    
    var title: String {
        switch type {
        case .week: return "\(number). Hafta"
        case .month: return "\(number). Ay"
        case .year: return "\(number). Yaş"
        }
    }
    
    enum PeriodType: String, Codable {
        case week
        case month
        case year
    }
}

class TestSim10 {
    var calendar = Calendar.current
    
    func run() {
        calendar.locale = Locale(identifier: "tr_TR")
        let currentDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 26, hour: 12))!
        let birthDate = calendar.date(from: DateComponents(year: 2024, month: 12, day: 26, hour: 12))!
        
        var flatPeriods: [TimelinePeriod] = []
        let totalWeeks = 60
        
        for week in 0...52 {
            let start = calendar.date(byAdding: .weekOfYear, value: week, to: birthDate)!
            let end = calendar.date(byAdding: .weekOfYear, value: week + 1, to: birthDate)!
            flatPeriods.append(TimelinePeriod(type: .week, number: week + 1, startDate: start, endDate: end))
        }
        
        let calcBirth = flatPeriods.first!.startDate
        print("Birth: \(calcBirth)")
        
        for p in flatPeriods {
            let m = calendar.dateComponents([.month], from: calcBirth, to: p.startDate).month ?? 0
            if p.number <= 6 {
                print("Week \(p.number): start=\(p.startDate), m=\(m), pMonth=\(min(m + 1, 12))")
            }
        }
    }
}

TestSim10().run()
