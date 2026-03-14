import Foundation
let calendar = Calendar.current
let birth = calendar.date(byAdding: .day, value: -100, to: Date())!
let d1 = calendar.dateComponents([.weekOfYear, .month, .year], from: birth, to: Date())
let d2 = calendar.dateComponents([.weekOfYear], from: birth, to: Date())
let d3 = calendar.dateComponents([.day], from: birth, to: Date())
print(d1.weekOfYear!)
print(d2.weekOfYear!)
print(d3.day! / 7)
