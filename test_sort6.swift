import Foundation

let calendar = Calendar.current
let birthDateStr = "2024-12-26 12:00:00 +0000"
let df = DateFormatter()
df.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
let birthDate = df.date(from: birthDateStr)!

var expectedPeriods: [(type: String, num: Int, start: Date)] = []
let totalWeeks = 61

for week in 0...52 {
    if let start = calendar.date(byAdding: .weekOfYear, value: week, to: birthDate) {
        expectedPeriods.append((".week", week + 1, start))
    }
}

let calcBirth = expectedPeriods.first!.start

// Group into months exactly as the app does
var periodsByMonth: [Int: [Int]] = [:]

for p in expectedPeriods {
    let m = calendar.dateComponents([.month], from: calcBirth, to: p.start).month ?? 0
    let pMonth = min(m + 1, 12)
    periodsByMonth[pMonth, default: []].append(p.num)
}

print("Month 1 contains weeks: \(periodsByMonth[1] ?? [])")
print("Month 2 contains weeks: \(periodsByMonth[2] ?? [])")
print("Month 3 contains weeks: \(periodsByMonth[3] ?? [])")
