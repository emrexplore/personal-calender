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
        if let customTitle = customTitle {
            return customTitle
        }
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

class TestBabyGrouping {
    let calendar = Calendar.current
    
    func run() {
        print("Scenraio 1: 1 Month old baby")
        let birthDate1 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let currentDate1 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 26))! // ~1 month, 11 days
        
        var periods1: [TimelinePeriod] = []
        for w in 1...7 {
            let start = calendar.date(byAdding: .weekOfYear, value: w-1, to: birthDate1)!
            let end = calendar.date(byAdding: .weekOfYear, value: w, to: birthDate1)!
            periods1.append(TimelinePeriod(type: .week, number: w, startDate: start, endDate: end))
        }
        
        let grouped1 = groupPeriodsByAge(periods1, currentDate: currentDate1)
        printTree(grouped1)
        
        print("\nScenraio 2: 15 Month old baby")
        let birthDate2 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let currentDate2 = calendar.date(from: DateComponents(year: 2026, month: 4, day: 5))! 
        
        var periods2: [TimelinePeriod] = []
        for w in 1...52 {
            let start = calendar.date(byAdding: .weekOfYear, value: w-1, to: birthDate2)!
            let end = calendar.date(byAdding: .weekOfYear, value: w, to: birthDate2)!
            periods2.append(TimelinePeriod(type: .week, number: w, startDate: start, endDate: end))
        }
        for m in 13...16 {
            let start = calendar.date(byAdding: .month, value: m-1, to: birthDate2)!
            let end = calendar.date(byAdding: .month, value: m, to: birthDate2)!
            periods2.append(TimelinePeriod(type: .month, number: m, startDate: start, endDate: end))
        }
        
        let grouped2 = groupPeriodsByAge(periods2, currentDate: currentDate2)
        printTree(grouped2)
    }
    
    func printTree(_ items: [TimelinePeriod], indent: String = "") {
        for item in items {
            print("\(indent)- \(item.title) (Start: \(item.startDate))")
            if let children = item.children {
                printTree(children, indent: indent + "  ")
            }
        }
    }
    
    private func groupPeriodsByAge(_ flatPeriods: [TimelinePeriod], currentDate: Date) -> [TimelinePeriod] {
        guard !flatPeriods.isEmpty else { return [] }
        
        // Find birthDate (startDate of Week 1)
        let birthDate = flatPeriods.first(where: { $0.type == .week && $0.number == 1 })?.startDate ?? flatPeriods.first!.startDate
        
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
                        groupedRoot.append(period) // Flat week
                    } else {
                        monthFoldersOfCurrentYear[pMonth, default: []].append(period)
                    }
                } else if period.type == .month {
                    groupedRoot.append(period) // Flat month
                }
            } else if pYear < currentBabyYear {
                pastYears[pYear, default: []].append(period)
            }
        }
        
        // Build folders for current year past months
        for (monthNum, weeks) in monthFoldersOfCurrentYear {
            let sortedWeeks = weeks.sorted { $0.startDate > $1.startDate }
            let minDate = weeks.map { $0.startDate }.min() ?? Date()
            let maxDate = weeks.map { $0.endDate }.max() ?? Date()
            
            let monthFolder = TimelinePeriod(
                type: .month,
                number: monthNum,
                startDate: minDate,
                endDate: maxDate,
                children: sortedWeeks
            )
            groupedRoot.append(monthFolder)
        }
        
        // Build folders for past years
        for (yearNum, periodsInYear) in pastYears {
            // Group weeks into months if year == 1
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
                let sortedWeeks = weeks.sorted { $0.startDate > $1.startDate }
                let minDate = weeks.map { $0.startDate }.min() ?? Date()
                let maxDate = weeks.map { $0.endDate }.max() ?? Date()
                let f = TimelinePeriod(type: .month, number: monthNum, startDate: minDate, endDate: maxDate, children: sortedWeeks)
                monthFolders.append(f)
            }
            
            monthFolders.sort { $0.startDate > $1.startDate }
            let minDate = periodsInYear.map { $0.startDate }.min() ?? Date()
            let maxDate = periodsInYear.map { $0.endDate }.max() ?? Date()
            
            let yearFolder = TimelinePeriod(
                type: .year,
                number: yearNum,
                startDate: minDate,
                endDate: maxDate,
                children: monthFolders
            )
            groupedRoot.append(yearFolder)
        }
        
        groupedRoot.sort { $0.startDate > $1.startDate }
        return groupedRoot
    }
}

TestBabyGrouping().run()
