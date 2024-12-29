//
//  Weight_Tracker_v2App.swift
//  Weight Tracker v2
//
//  Created by Simone Morgillo on 29/12/2024.
//

import SwiftUI

@main
struct Weight_Tracker_v2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
