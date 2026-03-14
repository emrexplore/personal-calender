import Foundation

struct TimelinePeriod: Identifiable {
    var id: UUID = UUID()
    let type: String
    let number: Int
    let children: [TimelinePeriod]?
    
    var title: String {
        return "\(type) \(number)"
    }
}

class TimelineManager {
    var periods: [TimelinePeriod] = []
    
    func groupPeriods() -> [TimelinePeriod] {
        var root: [TimelinePeriod] = []
        var pByMonth: [Int: [TimelinePeriod]] = [:]
        
        for p in periods {
            if p.type == "week" {
                pByMonth[1, default: []].append(p)
            }
        }
        
        for (monthNum, weeks) in pByMonth {
            let folder = TimelinePeriod(id: UUID(), type: "month", number: monthNum, children: weeks)
            root.append(folder)
        }
        
        return root
    }
}

let manager = TimelineManager()
// Diyelim sistemde kaydedilmiş orijinal 2 hafta var
let origWeek1 = TimelinePeriod(type: "week", number: 1, children: nil)
let origWeek2 = TimelinePeriod(type: "week", number: 2, children: nil)

manager.periods = [origWeek1, origWeek2]

let grouped = manager.groupPeriods()

print("Orijinal Week 1 ID'si: \(origWeek1.id)")
if let folder = grouped.first, let childWeek1 = folder.children?.first(where: { $0.number == 1 }) {
    print("Gruplanmış klasör içindeki Week 1 ID'si: \(childWeek1.id)")
    if origWeek1.id == childWeek1.id {
        print("✅ ID'ler aynı! UI listesinden asıl period'u bulabiliriz.")
    } else {
        print("❌ HATA: ID'ler farklı! UI asıl veriyi asla bulamaz.")
    }
}
