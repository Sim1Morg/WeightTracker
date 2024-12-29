//
//  Weight_TrackerApp.swift
//  Weight Tracker
//
//  Created by Simone Morgillo on 28/12/2024.
//

import SwiftUI

@main
struct Weight_TrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
