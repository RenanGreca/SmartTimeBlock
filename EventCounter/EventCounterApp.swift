//
//  EventCounterApp.swift
//  EventCounter
//
//  Created by Renan Greca on 02/02/23.
//

import SwiftUI

@main
struct EventCounterApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
