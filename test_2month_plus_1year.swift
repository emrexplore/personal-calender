import Foundation

struct MockTimelinePeriod: Equatable {
    let type: String
    let number: Int
    let startDate: Date
    let endDate: Date
}

class MockTimelineManager {
    var periods: [MockTimelinePeriod] = []
    let calendar = Calendar.current
    
    // Uygulamanın sıfırdan ilk açılışında çağırdığı method
    func generateTimeline(birthDate: Date, simulatedCurrentDate: Date) {
        let expected = generateExpectedPeriods(birthDate: birthDate, currentDate: simulatedCurrentDate)
        self.periods = expected.reversed() // Yeniden eskiye
    }
    
    // Bu method aslında 'generateExpectedPeriods'
    func generateExpectedPeriods(birthDate: Date, currentDate: Date) -> [MockTimelinePeriod] {
        var expectedPeriods: [MockTimelinePeriod] = []
        
        // TimelineManager.swift 29. satırdaki hesaplama
        let totalWeeks = (calendar.dateComponents([.day], from: birthDate, to: currentDate).day ?? 0) / 7
        let totalMonths = calendar.dateComponents([.month], from: birthDate, to: currentDate).month ?? 0
        
        let weeksToShow = min(totalWeeks, 52)
        if weeksToShow > 0 {
            for week in 0..<weeksToShow {
                if let start = calendar.date(byAdding: .weekOfYear, value: week, to: birthDate),
                   let end = calendar.date(byAdding: .weekOfYear, value: week + 1, to: birthDate) {
                    expectedPeriods.append(MockTimelinePeriod(type: "week", number: week + 1, startDate: start, endDate: end))
                }
            }
        }
        
        if totalMonths >= 12 {
            let monthsToShow = totalMonths + 1
            for month in 12..<monthsToShow {
                if let start = calendar.date(byAdding: .month, value: month, to: birthDate),
                   let end = calendar.date(byAdding: .month, value: month + 1, to: birthDate) {
                    expectedPeriods.append(MockTimelinePeriod(type: "month", number: month + 1, startDate: start, endDate: end))
                }
            }
        }
        
        return expectedPeriods
    }
    
    // Uygulama her açıldığında arka planda çağırdığı method (updateTimelineIfNeeded)
    func updateTimelineIfNeeded(birthDate: Date, simulatedCurrentDate: Date) {
        let expectedPeriods = generateExpectedPeriods(birthDate: birthDate, currentDate: simulatedCurrentDate)
        var didAddSomethingNew = false
        
        for expected in expectedPeriods {
            let exists = self.periods.contains { period in
                period.type == expected.type && period.number == expected.number
            }
            
            if !exists {
                self.periods.append(expected) // Eski verileri ezmeden ekler
                didAddSomethingNew = true
                print("🆕 SİSTEME YENİ DÖNEM EKLENDİ!: \(expected.type.uppercased()) \(expected.number)")
            }
        }
        
        if didAddSomethingNew {
            self.periods.sort { $0.startDate > $1.startDate } // Yeniden eskiye sıralama korunur
        }
    }
}

let df = ISO8601DateFormatter()
// Diyelim ki çocuk 1 Ocak 2026 doğumlu
let birthDate = df.date(from: "2026-01-01T12:00:00Z")!

let manager = MockTimelineManager()

let calendarInstance = Calendar.current
print("👶 SENARYO 1: Bebek 2 aylıkken (8-9 haftalık) uygulamaya kaydedildi.")
// 2 ay ortalama 60 gün, yaklaşık 8 buçuk hafta
let installDate = calendarInstance.date(byAdding: .month, value: 2, to: birthDate)! 
manager.generateTimeline(birthDate: birthDate, simulatedCurrentDate: installDate)

print("Ekranda görünen haftalar (Sadece ilk 4'ü loglanıyor):")
for p in manager.periods.prefix(4) {
    print(" - \(p.type) \(p.number)")
}
print("   (Toplam dönem sayısı: \(manager.periods.count))")

print("\n-----------------------")
print("⏳ 12 Ay (1 Yıl) geçti...")
print("📱 SENARYO 2: Ebeveyn 1 Yıl sonra uygulamayı tekrar açtı. (Çocuk tam 14 Aylık)")
let oneYearLater = calendarInstance.date(byAdding: .month, value: 12, to: installDate)!
// Uygulama açılışında arka planda çalışan update kodu tetiklenir:
manager.updateTimelineIfNeeded(birthDate: birthDate, simulatedCurrentDate: oneYearLater)

print("\nEkranda görünen son durum (En yeni 6 kayıt gösteriliyor):")
for p in manager.periods.prefix(6) {
    print(" - \(p.type) \(p.number)")
}
print("   (Toplam dönem sayısı: \(manager.periods.count))")
