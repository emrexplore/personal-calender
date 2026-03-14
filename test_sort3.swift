import Foundation

let calendar = Calendar.current
let birthDateStr = "2026-01-26 12:00:00 +0000"
let currentStr = "2026-02-26 12:00:00 +0000"
let df = DateFormatter()
df.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
let birthDate = df.date(from: birthDateStr)!
let currentDate = df.date(from: currentStr)!

print("Current: \(currentDate), Birth: \(birthDate)")

var expectedPeriods: [(type: String, num: Int, start: Date)] = []
let totalWeeks = (calendar.dateComponents([.day], from: birthDate, to: currentDate).day ?? 0) / 7
let weeksToShow = min(totalWeeks, 52)

for week in 0...weeksToShow {
    if let start = calendar.date(byAdding: .weekOfYear, value: week, to: birthDate) {
        expectedPeriods.append((".week", week + 1, start))
    }
}

let calcBirth = expectedPeriods.map { $0.start }.min() ?? Date()
for p in expectedPeriods {
    let m = calendar.dateComponents([.month], from: calcBirth, to: p.start).month ?? 0
    let pMonth = min(m + 1, 12)
    print("Period Week \(p.num): start=\(p.start), m=\(m), pMonth=\(pMonth)")
}
