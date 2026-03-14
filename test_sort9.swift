import Foundation

let calendar = Calendar.current
let df = DateFormatter()
df.dateFormat = "yyyy-MM-dd"

let birthDate = df.date(from: "2024-12-30")!
let week2 = df.date(from: "2025-01-06")!

let m = calendar.dateComponents([.month], from: birthDate, to: week2).month ?? 0

print("Month diff from \(birthDate) to \(week2) is: \(m)")
