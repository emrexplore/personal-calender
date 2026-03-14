import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Bildirim izni alınırken hata: \(error)")
                completion(false)
            } else {
                completion(granted)
                if granted {
                    print("Bildirim izni verildi.")
                } else {
                    print("Bildirim izni verilmedi.")
                }
            }
        }
    }
    
    func scheduleSmartNotification(birthDate: Date) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests() // Eski bildirimleri temizle
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: birthDate, to: Date())
        let totalMonths = components.month ?? 0
        
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        var dateComponents = DateComponents()
        // Kullanıcının isteği: Saat 18.00'da bildirim gitsin
        dateComponents.hour = 18
        dateComponents.minute = 0
        
        if totalMonths >= 12 {
            // 1 Yaş Sonrası -> Aylık bildirim
            content.title = "Yeni Bir Ay Başladı!"
            content.body = "Çocuğunuzun bu ayki gelişimini ve anılarını kaydetmeyi unutmayın."
            
            let birthDay = calendar.component(.day, from: birthDate)
            dateComponents.day = birthDay
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "MonthlyReminder", content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Aylık bildirim zamanlama hatası: \(error.localizedDescription)")
                } else {
                    print("Aylık \(birthDay). gün saat 18:00 için bildirim ayarlandı.")
                }
            }
        } else {
            // İlk 1 Yaş -> Haftalık bildirim
            content.title = "Yeni Bir Hafta Başladı!"
            content.body = "Çocuğunuzun bu haftaki gelişimini ve anılarını kaydetmeyi unutmayın."
            
            let birthWeekday = calendar.component(.weekday, from: birthDate)
            dateComponents.weekday = birthWeekday
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "WeeklyReminder", content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Haftalık bildirim zamanlama hatası: \(error.localizedDescription)")
                } else {
                    print("Haftalık \(birthWeekday). günü saat 18:00 için bildirim ayarlandı.")
                }
            }
        }
    }
}
