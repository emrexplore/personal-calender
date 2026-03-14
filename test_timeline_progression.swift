import Foundation

// Simulate exactly how TimelineManager models these calculations
struct MockTimelinePeriod: Equatable {
    let type: String
    let number: Int
    let startDate: Date
    let endDate: Date
}

class MockTimelineManager {
    var periods: [MockTimelinePeriod] = []
    let calendar = Calendar.current
    
    // Simulate generation for a given custom `currentDate`
    func generateExpectedPeriods(birthDate: Date, currentDate: Date) -> [MockTimelinePeriod] {
        var expectedPeriods: [MockTimelinePeriod] = []
        
        let totalWeeks = (calendar.dateComponents([.day], from: birthDate, to: currentDate).day ?? 0) / 7
        let totalMonths = calendar.dateComponents([.month], from: birthDate, to: currentDate).month ?? 0
        
        let weeksToShow = min(totalWeeks, 51)
        for week in 0...weeksToShow {
            if let start = calendar.date(byAdding: .weekOfYear, value: week, to: birthDate),
               let end = calendar.date(byAdding: .weekOfYear, value: week + 1, to: birthDate) {
                expectedPeriods.append(MockTimelinePeriod(type: "week", number: week + 1, startDate: start, endDate: end))
            }
        }
        
        if totalMonths >= 12 {
            for month in 12...totalMonths {
                if let start = calendar.date(byAdding: .month, value: month, to: birthDate),
                   let end = calendar.date(byAdding: .month, value: month + 1, to: birthDate) {
                    expectedPeriods.append(MockTimelinePeriod(type: "month", number: month + 1, startDate: start, endDate: end))
                }
            }
        }
        
        return expectedPeriods
    }
    
    // Simulate open app at a custom time 
    func updateTimelineIfNeeded(birthDate: Date, simulatedCurrentDate: Date) {
        let expectedPeriods = generateExpectedPeriods(birthDate: birthDate, currentDate: simulatedCurrentDate)
        var didAddSomethingNew = false
        
        for expected in expectedPeriods {
            let exists = self.periods.contains { period in
                period.type == expected.type && period.number == expected.number
            }
            
            if !exists {
                self.periods.append(expected)
                didAddSomethingNew = true
                print("🆕 YENİ EKLENDİ: TiP: \(expected.type.uppercased()), NO: \(expected.number)")
            }
        }
        
        if didAddSomethingNew {
            self.periods.sort { $0.startDate > $1.startDate }
        } else {
            print("  -> Değişiklik yok. Her şey güncel.")
        }
    }
}

let df = ISO8601DateFormatter()
let birthDate = df.date(from: "2024-01-01T12:00:00Z")!

let manager = MockTimelineManager()

print("🏁 ADIM 1: Uygulama bebek doğduktan tam 2 hafta sonra indirildi (15 Ocak 2024)")
let appInstallDate = df.date(from: "2024-01-15T12:00:00Z")! 
// İlk kurulumda listeyi dolduralım
manager.periods = manager.generateExpectedPeriods(birthDate: birthDate, currentDate: appInstallDate).reversed()
print("   Başlangıç dönemi sayısı: \(manager.periods.count) (Beklenen: 3 hafta [1,2,3])")
manager.periods.forEach { print("   Mevcut: \($0.type) \($0.number)") }

print("\n🚀 ADIM 2: Kullanıcı uygulamayı 1 ay sonra (15 Şubat 2024) açtı")
let openDate1 = df.date(from: "2024-02-15T12:00:00Z")!
manager.updateTimelineIfNeeded(birthDate: birthDate, simulatedCurrentDate: openDate1)

print("\n🔄 ADIM 3: Kullanıcı uygulamayı ertesi gün bir daha açtı (16 Şubat 2024)")
let openDate2 = df.date(from: "2024-02-16T12:00:00Z")!
manager.updateTimelineIfNeeded(birthDate: birthDate, simulatedCurrentDate: openDate2)

print("\n🚀 ADIM 4: Kullanıcı uygulamayı bebek 1. yaşına girdiğinde açtı (1 Ocak 2025)")
let openDate3 = df.date(from: "2025-01-01T12:00:00Z")!
manager.updateTimelineIfNeeded(birthDate: birthDate, simulatedCurrentDate: openDate3)

print("\n📊 SON LİSTE (En yeniden en eskiye ilk 5 eleman):")
for p in manager.periods.prefix(5) {
    print(" - \(p.type) \(p.number)")
}
