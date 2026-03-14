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

class TestSim7 {
    var calendar = Calendar.current
    
    func run() {
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        // Local currentDate in Turkey
        let currentDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 26, hour: 12))!
        // 1 year 2 months ago -> around Dec 26, 2024
        let birthDate = calendar.date(from: DateComponents(year: 2024, month: 12, day: 26, hour: 12))!
        
        var flatPeriods: [TimelinePeriod] = []
        let totalWeeks = (calendar.dateComponents([.day], from: birthDate, to: currentDate).day ?? 0) / 7
        
        for week in 0...min(totalWeeks, 52) {
            let start = calendar.date(byAdding: .weekOfYear, value: week, to: birthDate)!
            let end = calendar.date(byAdding: .weekOfYear, value: week + 1, to: birthDate)!
            flatPeriods.append(TimelinePeriod(type: .week, number: week + 1, startDate: start, endDate: end))
        }
        
        let sortedFlatPeriods = flatPeriods.sorted { $0.startDate < $1.startDate }
        let calcBirth = sortedFlatPeriods.first?.startDate ?? Date()
        
        var groupedRoot: [TimelinePeriod] = []
        var pastYears: [Int: [TimelinePeriod]] = [:]
        
        let currentMonthsSinceBirth = calendar.dateComponents([.month], from: calcBirth, to: currentDate).month ?? 0
        let currentBabyMonth = currentMonthsSinceBirth + 1
        let currentBabyYear = (currentBabyMonth - 1) / 12 + 1
        
        for period in sortedFlatPeriods {
            var pMonth = 1
            var pYear = 1
            if period.type == .week {
                let m = calendar.dateComponents([.month], from: calcBirth, to: period.startDate).month ?? 0
                pMonth = min(m + 1, 12)
                pYear = 1
            }
            if pYear < currentBabyYear {
                pastYears[pYear, default: []].append(period)
            }
        }
        
        for (yearNum, periodsInYear) in pastYears {
            var monthFolders: [TimelinePeriod] = []
            var periodsByMonth: [Int: [TimelinePeriod]] = [:]
            for p in periodsInYear {
                if p.type == .week {
                    let m = calendar.dateComponents([.month], from: calcBirth, to: p.startDate).month ?? 0
                    let pMonth = min(m + 1, 12)
                    periodsByMonth[pMonth, default: []].append(p)
                }
            }
            
            for (monthNum, weeks) in periodsByMonth {
                let sortedWeeks = weeks.sorted { $0.startDate < $1.startDate }
                monthFolders.append(TimelinePeriod(type: .month, number: monthNum, startDate: weeks.first!.startDate, endDate: weeks.last!.endDate, children: sortedWeeks))
            }
            
            monthFolders.sort { $0.startDate < $1.startDate }
            groupedRoot.append(TimelinePeriod(type: .year, number: yearNum, startDate: periodsInYear.first!.startDate, endDate: periodsInYear.last!.endDate, children: monthFolders))
        }
        
        for yearFolder in groupedRoot {
            print(yearFolder.title)
            for monthFolder in yearFolder.children ?? [] {
                if monthFolder.number == 1 {
                    print("  - \(monthFolder.title):")
                    for week in monthFolder.children ?? [] {
                        print("    - \(week.title)")
                    }
                }
            }
        }
    }
}

TestSim7().run()
