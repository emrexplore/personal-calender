//
//  personal_calenderApp.swift
//  personal calender
//
//  Created by Emre URUL on 23.02.2026.
//

import SwiftUI
import CoreData

@main
struct personal_calenderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
