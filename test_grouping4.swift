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
        case .month: 
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "LLLL yyyy"
            monthFormatter.locale = Locale(identifier: "tr_TR")
            return monthFormatter.string(from: startDate).capitalized
        case .year: return "\(number). Yıl"
        }
    }
    
    enum PeriodType: String, Codable {
        case week
        case month
        case year
    }
}

class TestGrouping {
    let calendar = Calendar.current
    
    func run() {
        var dummyPeriods: [TimelinePeriod] = []
        var currentDate = calendar.date(from: DateComponents(year: 2024, month: 11, day: 1))!
        
        // Ilk yil (Haftalar)
        for week in 1...5 {
            let endDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate)!
            dummyPeriods.append(TimelinePeriod(type: .week, number: week, startDate: currentDate, endDate: endDate))
            currentDate = endDate
        }
        
        // 1 yas sonrasi (Aylar) - Ornegin 13. Ay
        for month in 13...24 { // Number is irrelevant to calendar date
            let endDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
            dummyPeriods.append(TimelinePeriod(type: .month, number: month, startDate: currentDate, endDate: endDate))
            currentDate = endDate
        }

        let result = groupPeriodsByYearAndMonth(dummyPeriods)
        print("--- RESULT ---")
        for item in result {
            print("- \(item.title) (Type: \(item.type))")
            if let children = item.children {
                for child in children {
                    print("  - \(child.title) (Type: \(child.type))")
                    if let grandchildren = child.children {
                        for grand in grandchildren {
                            print("    - \(grand.title) (Type: \(grand.type))")
                        }
                    }
                }
            }
        }
    }
    
    private func groupPeriodsByYearAndMonth(_ flatPeriods: [TimelinePeriod]) -> [TimelinePeriod] {
        guard !flatPeriods.isEmpty else { return [] }
        
        let currentDate = Date()
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "LLLL yyyy"
        monthFormatter.locale = Locale(identifier: "tr_TR")
        
        var groupedResult: [TimelinePeriod] = []
        var periodsByYear: [Int: [TimelinePeriod]] = [:] 
        
        for period in flatPeriods {
            let periodYear = calendar.component(.year, from: period.startDate)
            let periodMonth = calendar.component(.month, from: period.startDate)
            
            // "Bu ay" kontrolu. Eger period icinde bulundugumuz takvim ayindaysa (.week veya .month) ana ekranda duz kalir.
            if periodYear == currentYear && periodMonth == currentMonth {
                groupedResult.append(period)
            } else {
                periodsByYear[periodYear, default: []].append(period)
            }
        }
        
        let sortedYears = periodsByYear.keys.sorted(by: >)
        
        for year in sortedYears {
            let periodsInThatYear = periodsByYear[year] ?? []
            guard !periodsInThatYear.isEmpty else { continue }
            
            if year == currentYear {
                let monthsInCurrentYear = groupToMonths(periodsInThatYear, year: year, calendar: calendar, formatter: monthFormatter)
                groupedResult.append(contentsOf: monthsInCurrentYear)
            } else {
                let monthsInPastYear = groupToMonths(periodsInThatYear, year: year, calendar: calendar, formatter: monthFormatter)
                
                let yearTitle = "\(year) Yılı"
                let minDate = periodsInThatYear.map { $0.startDate }.min() ?? Date()
                let maxDate = periodsInThatYear.map { $0.endDate }.max() ?? Date()
                
                let yearPeriod = TimelinePeriod(
                    type: .year,
                    number: year,
                    startDate: minDate,
                    endDate: maxDate,
                    customTitle: yearTitle,
                    children: monthsInPastYear
                )
                groupedResult.append(yearPeriod)
            }
        }
        
        groupedResult.sort { $0.startDate > $1.startDate }
        return groupedResult
    }
    
    private func groupToMonths(_ periods: [TimelinePeriod], year: Int, calendar: Calendar, formatter: DateFormatter) -> [TimelinePeriod] {
        var periodsByMonth: [Int: [TimelinePeriod]] = [:]
        var standalonePeriods: [TimelinePeriod] = []
        
        for p in periods {
            if p.type == .week {
                // Sadece haftalari takvim ayina sarmalariz
                let m = calendar.component(.month, from: p.startDate)
                periodsByMonth[m, default: []].append(p)
            } else {
                // Eger zaten Aysa (örn: 13. Ay -> Şubat 2025) hicbir seye sarilmaz
                standalonePeriods.append(p)
            }
        }
        
        var monthNodes: [TimelinePeriod] = []
        let sortedMonths = periodsByMonth.keys.sorted(by: >)
        
        for month in sortedMonths {
            let periodsInMonth = periodsByMonth[month] ?? []
            guard let sampleDate = periodsInMonth.first?.startDate else { continue }
            let title = formatter.string(from: sampleDate).capitalized
            
            let minDate = periodsInMonth.map { $0.startDate }.min() ?? Date()
            let maxDate = periodsInMonth.map { $0.endDate }.max() ?? Date()
            let sortedChildren = periodsInMonth.sorted { $0.startDate > $1.startDate }
            
            let monthPeriod = TimelinePeriod(
                type: .month,
                number: month,
                startDate: minDate,
                endDate: maxDate,
                customTitle: title, // customTitle ile isim atanir
                children: sortedChildren
            )
            
            monthNodes.append(monthPeriod)
        }
        
        var finalNodes = monthNodes + standalonePeriods
        finalNodes.sort { $0.startDate > $1.startDate }
        
        return finalNodes
    }
}

TestGrouping().run()
