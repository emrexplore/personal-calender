import Foundation

let calendar = Calendar.current
let df = DateFormatter()
df.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
let birthDate = df.date(from: "2024-12-26 12:00:00 +0000")!

var expectedPeriods: [(type: String, num: Int, start: Date)] = []
for week in 0...52 {
    if let start = calendar.date(byAdding: .weekOfYear, value: week, to: birthDate) {
        expectedPeriods.append((".week", week + 1, start))
    }
}

let calcBirth = expectedPeriods.first!.start

var periodsByMonth: [Int: [Int]] = [:]

for p in expectedPeriods {
    let daysSinceBirth = calendar.dateComponents([.day], from: calcBirth, to: p.start).day ?? 0
    let calculatedMonth = Int(Double(daysSinceBirth) / 30.4375)
    let pMonth = min(calculatedMonth + 1, 12)
    periodsByMonth[pMonth, default: []].append(p.num)
}

for i in 1...12 {
    print("Month \(i) contains weeks: \(periodsByMonth[i] ?? [])")
}
