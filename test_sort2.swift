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

class TestSim2 {
    let calendar = Calendar.current
    
    func run() {
        let birthDates = [
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 20))!, // Jan 20
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!, // Jan 31
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!,  // Jan 1
            calendar.date(from: DateComponents(year: 2025, month: 12, day: 25))! // Dec 25
        ]
        let currentDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 26))!
        
        for birthDate in birthDates {
            print("=== BirthDate: \(birthDate) ===")
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
            flatPeriods.sort { $0.startDate > $1.startDate }
            let groupedRoot = groupPeriodsByYearAndMonth(flatPeriods, currentDate: currentDate)
            
            // Check Month 1:
            if let month1 = findMonth1(in: groupedRoot) {
                print("Month 1 has \(month1.children?.count ?? 0) weeks:")
                for child in month1.children ?? [] {
                    print("  - \(child.title)")
                }
            } else {
                print("Month 1 NOT FOUND! (Probably current month, so weeks are flat)")
                print("Flat weeks:")
                for child in groupedRoot where child.type == .week {
                    print("  - \(child.title)")
                }
            }
        }
    }
    
    func findMonth1(in items: [TimelinePeriod]) -> TimelinePeriod? {
        for item in items {
            if item.type == .month && item.number == 1 { return item }
            if let children = item.children, let found = findMonth1(in: children) { return found }
        }
        return nil
    }
    
    // Paste exact grouping logic from TimelineManager.swift
    private func groupPeriodsByYearAndMonth(_ flatPeriods: [TimelinePeriod], currentDate: Date) -> [TimelinePeriod] {
        guard !flatPeriods.isEmpty else { return [] }
        let calendar = Calendar.current
        let birthDate = flatPeriods.map { $0.startDate }.min() ?? Date()
        
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
            } else {
                groupedRoot.append(period)
            }
        }
        
        for (monthNum, weeks) in monthFoldersOfCurrentYear {
            let sortedWeeks = weeks.sorted { $0.startDate < $1.startDate }
            let minDate = weeks.map { $0.startDate }.min() ?? Date()
            let maxDate = weeks.map { $0.endDate }.max() ?? Date()
            groupedRoot.append(TimelinePeriod(type: .month, number: monthNum, startDate: minDate, endDate: maxDate, children: sortedWeeks))
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
                let minDate = weeks.map { $0.startDate }.min() ?? Date()
                let maxDate = weeks.map { $0.endDate }.max() ?? Date()
                monthFolders.append(TimelinePeriod(type: .month, number: monthNum, startDate: minDate, endDate: maxDate, children: sortedWeeks))
            }
            
            monthFolders.sort { $0.startDate < $1.startDate }
            
            let minDate = periodsInYear.map { $0.startDate }.min() ?? Date()
            let maxDate = periodsInYear.map { $0.endDate }.max() ?? Date()
            
            groupedRoot.append(TimelinePeriod(type: .year, number: yearNum, startDate: minDate, endDate: maxDate, children: monthFolders))
        }
        
        groupedRoot.sort { $0.startDate > $1.startDate }
        return groupedRoot
    }
}
TestSim2().run()
