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

class TestSim5 {
    let calendar = Calendar.current
    
    func run() {
        let currentDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 26))!
        
        var d = calendar.date(from: DateComponents(year: 2024, month: 11, day: 1))!
        let endD = calendar.date(from: DateComponents(year: 2025, month: 2, day: 28))!
        
        var failures = 0
        
        while d <= endD {
            let birthDate = d
            
            var flatPeriods: [TimelinePeriod] = []
            let totalWeeks = (calendar.dateComponents([.day], from: birthDate, to: currentDate).day ?? 0) / 7
            for week in 0...min(totalWeeks, 52) {
                let start = calendar.date(byAdding: .weekOfYear, value: week, to: birthDate)!
                let end = calendar.date(byAdding: .weekOfYear, value: week + 1, to: birthDate)!
                flatPeriods.append(TimelinePeriod(type: .week, number: week + 1, startDate: start, endDate: end))
            }
            
            let calcBirth = flatPeriods.first?.startDate ?? Date()
            var monthContents: [Int: [Int]] = [:] // pMonth -> [week numbers]
            
            for p in flatPeriods {
                let m = calendar.dateComponents([.month], from: calcBirth, to: p.startDate).month ?? 0
                let pMonth = min(m + 1, 12)
                monthContents[pMonth, default: []].append(p.number)
            }
            
            if let month1 = monthContents[1] {
                if !month1.contains(1) { // If Week 1 is NOT in Month 1
                    print("FAIL: BirthDate \(birthDate). Month 1 contains: \(month1). Where is week 1? In month \(monthContents.first(where: { $1.contains(1) })?.key ?? -99)")
                    failures += 1
                }
            } else {
                print("FAIL: BirthDate \(birthDate). Month 1 DOES NOT EXIST")
                failures += 1
            }
            
            d = calendar.date(byAdding: .day, value: 1, to: d)!
        }
        
        print("Total failures: \(failures)")
    }
}

TestSim5().run()
