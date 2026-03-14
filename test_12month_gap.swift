import Foundation

let calendar = Calendar.current
let df = ISO8601DateFormatter()

func testGenerate(birthDate: Date, currentDate: Date) {
    let totalWeeks = (calendar.dateComponents([.day], from: birthDate, to: currentDate).day ?? 0) / 7
    let totalMonths = calendar.dateComponents([.month], from: birthDate, to: currentDate).month ?? 0
    
    var expected: [String] = []
    
    let weeksToShow = min(totalWeeks, 51)
    for week in 0...weeksToShow {
        expected.append("Week \(week + 1)")
    }
    
    if totalMonths >= 12 { // Trying >= 12 instead of > 12
        for month in 12...totalMonths {
             expected.append("Month \(month + 1)")
        }
    }
    
    print("Total Months: \(totalMonths), Total Weeks: \(totalWeeks)")
    print("Last parts of expected:")
    print(expected.suffix(5).joined(separator: ", "))
}

let birth = df.date(from: "2024-01-01T12:00:00Z")!
// Test exactly 12 months and 5 days
let current = df.date(from: "2025-01-06T12:00:00Z")! 

testGenerate(birthDate: birth, currentDate: current)
