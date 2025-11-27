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
    @State private var settings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView(settings: settings)
        }
        .modelContainer(for: [Feed.self, Article.self, Folder.self])
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Feed...") {
                    NotificationCenter.default.post(name: .addFeedRequested, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Add Folder...") {
                    NotificationCenter.default.post(name: .addFolderRequested, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .newItem) {
                Button("Refresh All") {
                    NotificationCenter.default.post(name: .refreshAllRequested, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Divider()
                
                Button("Next Article") {
                    NotificationCenter.default.post(name: .nextArticleRequested, object: nil)
                }
                .keyboardShortcut("j", modifiers: [])
                
                Button("Previous Article") {
                    NotificationCenter.default.post(name: .previousArticleRequested, object: nil)
                }
                .keyboardShortcut("k", modifiers: [])
                
                Button("Toggle Read Status") {
                    NotificationCenter.default.post(name: .toggleReadRequested, object: nil)
                }
                .keyboardShortcut("u", modifiers: [])
                
                Button("Toggle Star") {
                    NotificationCenter.default.post(name: .toggleStarRequested, object: nil)
                }
                .keyboardShortcut("s", modifiers: [])
                
                Button("Open in Browser") {
                    NotificationCenter.default.post(name: .openInBrowserRequested, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView(settings: settings)
        }
    }
}

extension Notification.Name {
    static let addFeedRequested = Notification.Name("addFeedRequested")
    static let addFolderRequested = Notification.Name("addFolderRequested")
    static let refreshAllRequested = Notification.Name("refreshAllRequested")
    static let nextArticleRequested = Notification.Name("nextArticleRequested")
    static let previousArticleRequested = Notification.Name("previousArticleRequested")
    static let toggleReadRequested = Notification.Name("toggleReadRequested")
    static let toggleStarRequested = Notification.Name("toggleStarRequested")
    static let openInBrowserRequested = Notification.Name("openInBrowserRequested")
}
