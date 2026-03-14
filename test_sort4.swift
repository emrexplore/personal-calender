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

class TestSim4 {
    let calendar = Calendar.current
    
    func run() {
        let currentDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 26))!
        let birthDate = calendar.date(from: DateComponents(year: 2024, month: 12, day: 26))! // 1 year, 2 months ago
        
        var flatPeriods: [TimelinePeriod] = []
        let totalWeeks = (calendar.dateComponents([.day], from: birthDate, to: currentDate).day ?? 0) / 7
        let totalMonths = calendar.dateComponents([.month], from: birthDate, to: currentDate).month ?? 0
        
        for week in 0...min(totalWeeks, 52) {
            let start = calendar.date(byAdding: .weekOfYear, value: week, to: birthDate)!
            let end = calendar.date(byAdding: .weekOfYear, value: week + 1, to: birthDate)!
            flatPeriods.append(TimelinePeriod(type: .week, number: week + 1, startDate: start, endDate: end))
        }
        if totalMonths > 12 {
            for month in 12...totalMonths {
                let start = calendar.date(byAdding: .month, value: month, to: birthDate)!
                let end = calendar.date(byAdding: .month, value: month + 1, to: birthDate)!
                flatPeriods.append(TimelinePeriod(type: .month, number: month + 1, startDate: start, endDate: end))
            }
        }
        flatPeriods.sort { $0.startDate < $1.startDate }
        
        let currentMonthsSinceBirth = calendar.dateComponents([.month], from: birthDate, to: currentDate).month ?? 0
        let currentBabyMonth = currentMonthsSinceBirth + 1
        let currentBabyYear = (currentBabyMonth - 1) / 12 + 1
        
        var groupedRoot: [TimelinePeriod] = []
        var pastYears: [Int: [TimelinePeriod]] = [:]
        var monthFoldersOfCurrentYear: [Int: [TimelinePeriod]] = [:]
        
        for period in flatPeriods {
            var pMonth = 1
            var pYear = 1
            
            if period.type == .week {
                let m = calendar.dateComponents([.month], from: birthDate, to: period.startDate).month ?? 0
                pMonth = min(m + 1, 12)
                pYear = 1
            } else if period.type == .month {
                pMonth = period.number
                pYear = (pMonth - 1) / 12 + 1
            } else {
                groupedRoot.append(period)
                continue
            }
            
            if pYear == currentBabyYear {
                if period.type == .week {
                    if pMonth == currentBabyMonth {
                        groupedRoot.append(period)
                    } else {
                        monthFoldersOfCurrentYear[pMonth, default: []].append(period)
                    }
                } else if period.type == .month {
                    groupedRoot.append(period)
                }
            } else if pYear < currentBabyYear {
                pastYears[pYear, default: []].append(period)
            } else {
                groupedRoot.append(period)
            }
        }
        
        for (monthNum, weeks) in monthFoldersOfCurrentYear {
            let sortedWeeks = weeks.sorted { $0.startDate < $1.startDate }
            groupedRoot.append(TimelinePeriod(type: .month, number: monthNum, startDate: weeks.first!.startDate, endDate: weeks.last!.endDate, children: sortedWeeks))
        }
        
        for (yearNum, periodsInYear) in pastYears {
            var monthFolders: [TimelinePeriod] = []
            var periodsByMonth: [Int: [TimelinePeriod]] = [:]
            
            for p in periodsInYear {
                if p.type == .week {
                    let m = calendar.dateComponents([.month], from: birthDate, to: p.startDate).month ?? 0
                    let pMonth = min(m + 1, 12)
                    periodsByMonth[pMonth, default: []].append(p)
                } else {
                    monthFolders.append(p)
                }
            }
            
            for (monthNum, weeks) in periodsByMonth {
                let sortedWeeks = weeks.sorted { $0.startDate < $1.startDate }
                monthFolders.append(TimelinePeriod(type: .month, number: monthNum, startDate: weeks.first!.startDate, endDate: weeks.last!.endDate, children: sortedWeeks))
            }
            
            monthFolders.sort { $0.startDate < $1.startDate }
            groupedRoot.append(TimelinePeriod(type: .year, number: yearNum, startDate: periodsInYear.first!.startDate, endDate: periodsInYear.last!.endDate, children: monthFolders))
        }
        
        groupedRoot.sort { $0.startDate > $1.startDate }
        
        printTree(groupedRoot)
    }
    
    func printTree(_ items: [TimelinePeriod], indent: String = "") {
        for item in items {
            print("\(indent)- \(item.title)")
            if let children = item.children {
                printTree(children, indent: indent + "  ")
            }
        }
    }
}

TestSim4().run()
