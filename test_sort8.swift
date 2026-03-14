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

class ExactSim {
    var periods: [TimelinePeriod] = []

    func generateExpectedPeriods(birthDate: Date, currentDate: Date) -> [TimelinePeriod] {
        var expectedPeriods: [TimelinePeriod] = []
        let calendar = Calendar.current
        
        let totalWeeks = (calendar.dateComponents([.day], from: birthDate, to: currentDate).day ?? 0) / 7
        let totalMonths = calendar.dateComponents([.month], from: birthDate, to: currentDate).month ?? 0
        
        // İlk yıl (52 hafta)
        let weeksToShow = min(totalWeeks, 52)
        for week in 0...weeksToShow {
            if let start = calendar.date(byAdding: .weekOfYear, value: week, to: birthDate),
               let end = calendar.date(byAdding: .weekOfYear, value: week + 1, to: birthDate) {
                expectedPeriods.append(TimelinePeriod(type: .week, number: week + 1, startDate: start, endDate: end))
            }
        }
        
        // 1 Yaş Sonrası (Aylık Dönemler - Sınırsız)
        if totalMonths > 12 {
            for month in 12...totalMonths {
                if let start = calendar.date(byAdding: .month, value: month, to: birthDate),
                   let end = calendar.date(byAdding: .month, value: month + 1, to: birthDate) {
                    expectedPeriods.append(TimelinePeriod(type: .month, number: month + 1, startDate: start, endDate: end))
                }
            }
        }
        
        return expectedPeriods
    }

    func generateTimeline(birthDate: Date, currentDate: Date) {
        let expected = generateExpectedPeriods(birthDate: birthDate, currentDate: currentDate)
        self.periods = expected.reversed() // Yeniden eskiye sıralama
    }

    func groupPeriodsByYearAndMonth(_ flatPeriods: [TimelinePeriod], currentDate: Date) -> [TimelinePeriod] {
        guard !flatPeriods.isEmpty else { return [] }
        let sortedFlatPeriods = flatPeriods.sorted { $0.startDate < $1.startDate }
        
        let calendar = Calendar.current
        
        // Find birthDate strictly by grabbing the oldest date to prevent negative month indexes
        let birthDate = sortedFlatPeriods.first?.startDate ?? Date()
        
        let currentMonthsSinceBirth = calendar.dateComponents([.month], from: birthDate, to: currentDate).month ?? 0
        let currentBabyMonth = currentMonthsSinceBirth + 1
        let currentBabyYear = (currentBabyMonth - 1) / 12 + 1
        
        var groupedRoot: [TimelinePeriod] = []
        var pastYears: [Int: [TimelinePeriod]] = [:]
        var monthFoldersOfCurrentYear: [Int: [TimelinePeriod]] = [:]
        
        for period in sortedFlatPeriods {
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
                let folder = TimelinePeriod(type: .month, number: monthNum, startDate: minDate, endDate: maxDate, children: sortedWeeks)
                monthFolders.append(folder)
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

// Emulate user workflow
let sim = ExactSim()
let cal = Calendar.current
let currentDate = cal.date(from: DateComponents(year: 2026, month: 2, day: 26, hour: 12))!
// 1 year 2 months old creates birth date around Dec 26, 2024
let birthDate = cal.date(from: DateComponents(year: 2024, month: 12, day: 26, hour: 12))!

sim.generateTimeline(birthDate: birthDate, currentDate: currentDate)
let finalRoot = sim.groupPeriodsByYearAndMonth(sim.periods, currentDate: currentDate)

for item in finalRoot {
    print(item.title)
    for c1 in item.children ?? [] {
        print("  - \(c1.title)")
        if c1.number == 1 {
            for c2 in c1.children ?? [] {
                print("    - \(c2.title)")
            }
        }
    }
}
