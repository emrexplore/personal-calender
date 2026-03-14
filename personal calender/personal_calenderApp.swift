//
//  personal_calenderApp.swift
//  personal calender
//
//  Created by Emre URUL on 23.02.2026.
//

import SwiftUI

@main
struct personal_calenderApp: App {
    init() {
        print("DEBUG: App Init Started")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("DEBUG: ContentView onAppear")
                    NotificationManager.shared.requestAuthorization()
                    
                    // Mevcut profil varsa bildirim kuralını tekrar çek edip güvence altına alalım.
                    if let savedProfile = StorageManager.shared.loadProfile() {
                        NotificationManager.shared.scheduleSmartNotification(birthDate: savedProfile.birthDate)
                    }
                }
        }
    }
}
