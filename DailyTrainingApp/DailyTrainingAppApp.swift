//
//  DailyTrainingAppApp.swift
//  DailyTrainingApp
//
//  Created by 宁侠 on 2025/4/25.
//

import SwiftUI

@main
struct DailyTrainingAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
