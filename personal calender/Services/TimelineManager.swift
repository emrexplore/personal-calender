import Foundation
import Combine

class TimelineManager: ObservableObject {
    @Published var periods: [TimelinePeriod] = [] {
        didSet {
            // Sadece başlarken load eden boş durumda üstüne yazmasını engellemek için küçük bir kontrol:
            // Eğer boşaldıysa ve aslında siliş yapmıyorsak save etmesek de olur ama MVP için şimdilik her durumu kaydediyoruz.
            save()
        }
    }
    
    // UI için gruplanmış versiyon
    var groupedPeriods: [TimelinePeriod] {
        return groupPeriodsByYearAndMonth(self.periods)
    }
    
    // Hangi çocuğun verilerini yönettiğini anlaması için
    var childID: UUID?
    
    // Doğum tarihinden itibaren bugüne kadar *olması gereken* tüm dönemlerin iskeletini döner.
    private func generateExpectedPeriods(birthDate: Date) -> [TimelinePeriod] {
        var expectedPeriods: [TimelinePeriod] = []
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Toplam geçen hafta ve ay sayılarını doğru ve net hesaplamak için ayrı ayrı soruyoruz.
        // [.weekOfYear, .month, .year] aynı anda sorulursa haftaları aydan arta kalan olarak verir.
        let totalWeeks = (calendar.dateComponents([.day], from: birthDate, to: currentDate).day ?? 0) / 7
        let totalMonths = calendar.dateComponents([.month], from: birthDate, to: currentDate).month ?? 0
        
        // İlk yıl (52 hafta)
        let weeksToShow = min(totalWeeks, 52)
        if weeksToShow > 0 {
            for week in 0..<weeksToShow {
                if let start = calendar.date(byAdding: .weekOfYear, value: week, to: birthDate),
                   let end = calendar.date(byAdding: .weekOfYear, value: week + 1, to: birthDate) {
                    expectedPeriods.append(TimelinePeriod(type: .week, number: week + 1, startDate: start, endDate: end))
                }
            }
        }
        
        // 1 Yaş Sonrası (Aylık Dönemler - Sınırsız)
        if totalMonths >= 12 {
            // totalMonths kaç ise, o ay bitmiş ve yenisine girilmiş demektir veya içindeyizdir. 
            // Örneğin 12 ay bitince 13. aya giriyoruz. 
            let monthsToShow = totalMonths + 1
            for month in 12..<monthsToShow {
                if let start = calendar.date(byAdding: .month, value: month, to: birthDate),
                   let end = calendar.date(byAdding: .month, value: month + 1, to: birthDate) {
                    expectedPeriods.append(TimelinePeriod(type: .month, number: month + 1, startDate: start, endDate: end))
                }
            }
        }
        
        return expectedPeriods
    }
    
    // Uygulama ilk açıldığında sıfırdan kurmak için
    func generateTimeline(birthDate: Date) {
        let expected = generateExpectedPeriods(birthDate: birthDate)
        self.periods = expected.reversed() // Yeniden eskiye sıralama
        save()
    }
    
    // Gelen yeni haftaları tespit edip, mevcut listeye ekler (Eski verileri ezmeden)
    func updateTimelineIfNeeded(birthDate: Date) {
        let expectedPeriods = generateExpectedPeriods(birthDate: birthDate)
        var didAddSomethingNew = false
        
        for expected in expectedPeriods {
            // Mevcut dönemlerde bu dönem tipi ve numarası var mı?
            let exists = self.periods.contains { period in
                period.type == expected.type && period.number == expected.number
            }
            
            // Eğer yoksa (yeni bir haftaya / aya girilmişse) yeni yapıyı ekle
            if !exists {
                self.periods.append(expected)
                didAddSomethingNew = true
            }
        }
        
        // Eğer yeni şeyler eklendiyse, sıralamayı (Yeniden Eskiye) bozmamak için tekrar sırala
        if didAddSomethingNew {
            self.periods.sort { $0.startDate > $1.startDate }
            save()
        }
    }
    
    // Değişiklikleri diske kaydet
    func save() {
        if let id = childID {
            StorageManager.shared.savePeriods(periods, for: id)
        }
    }
    
    // Diskten yükle
    func load() {
        if let id = childID {
            if let savedPeriods = StorageManager.shared.loadPeriods(for: id) {
                self.periods = savedPeriods
            } else {
                // If it's a new child, ensure we don't accidentally leak old child's data
                self.periods = []
            }
        }
    }
    
    // MARK: - Grouping Logic
    private func groupPeriodsByYearAndMonth(_ flatPeriods: [TimelinePeriod]) -> [TimelinePeriod] {
        guard !flatPeriods.isEmpty else { return [] }
        
        // İlk giren veriyi baştan mutlaka eskiden yeniye (kronolojik, 1-2-3-4 diye) sıralayalım
        // Böylece array'lere eklerken ters listeleme riskini tamamen sıfırlıyoruz.
        let sortedFlatPeriods = flatPeriods.sorted { $0.startDate < $1.startDate }
        
        let calendar = Calendar.current
        let currentDate = Date()
        
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
                        // Burada append edildiğinde sortedFlatPeriods'dan geldiği için 1, 2, 3, 4 olarak eklenecek.
                        monthFoldersOfCurrentYear[pMonth, default: []].append(period)
                    }
                } else if period.type == .month {
                    groupedRoot.append(period) // Flat month
                }
            } else if pYear < currentBabyYear {
                pastYears[pYear, default: []].append(period)
            } else {
                // If it's a future year (shouldn't realistically happen yet, but just in case)
                groupedRoot.append(period)
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
            var monthFolders: [TimelinePeriod] = []
            var periodsByMonth: [Int: [TimelinePeriod]] = [:]
            
            // Eğer Yıl 1 (haftalık veriler barındıran yıl) ise ayları klasörlere ayır
            for p in periodsInYear {
                if p.type == .week {
                    let m = calendar.dateComponents([.month], from: birthDate, to: p.startDate).month ?? 0
                    let pMonth = min(m + 1, 12)
                    periodsByMonth[pMonth, default: []].append(p)
                } else {
                    monthFolders.append(p)
                }
            }
            
            // Hafta olanları sarmaladığımız klasörleri oluştur
            for (monthNum, weeks) in periodsByMonth {
                let sortedWeeks = weeks.sorted { $0.startDate > $1.startDate }
                let minDate = weeks.map { $0.startDate }.min() ?? Date()
                let maxDate = weeks.map { $0.endDate }.max() ?? Date()
                let folder = TimelinePeriod(type: .month, number: monthNum, startDate: minDate, endDate: maxDate, children: sortedWeeks)
                monthFolders.append(folder)
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
        
        // Son olarak hepsini tarihe göre yeniden eskiye (yukarıdan aşağıya) sırala
        groupedRoot.sort { $0.startDate > $1.startDate }
        return groupedRoot
    }
}
