//
//  testEnvironmentApp.swift
//  testEnvironment
//
//  Created by Kyryl Horbushko on 12/15/20.
//

import SwiftUI

@main
struct testEnvironmentApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
