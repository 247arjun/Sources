//
//  SourcesApp.swift
//  Sources
//
//  Created on November 26, 2025.
//

import SwiftUI
import SwiftData

@main
struct SourcesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Feed.self, Article.self])
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Feed...") {
                    NotificationCenter.default.post(name: .addFeedRequested, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let addFeedRequested = Notification.Name("addFeedRequested")
}
