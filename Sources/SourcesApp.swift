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
            // File Menu
            CommandGroup(replacing: .newItem) {
                Button("Add Feed...") {
                    NotificationCenter.default.post(name: .addFeedRequested, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Add Folder...") {
                    NotificationCenter.default.post(name: .addFolderRequested, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Import OPML...") {
                    NotificationCenter.default.post(name: .importOPMLRequested, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
                
                Button("Export OPML...") {
                    NotificationCenter.default.post(name: .exportOPMLRequested, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .option])
            }
            
            // Edit Menu
            CommandGroup(after: .pasteboard) {
                Divider()
                
                Button("Select All Articles") {
                    NotificationCenter.default.post(name: .selectAllArticlesRequested, object: nil)
                }
                .keyboardShortcut("a", modifiers: .command)
                
                Button("Deselect All") {
                    NotificationCenter.default.post(name: .deselectAllRequested, object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)
            }
            
            // View Menu
            CommandGroup(after: .sidebar) {
                Button("Show All Feeds") {
                    NotificationCenter.default.post(name: .showAllFeedsRequested, object: nil)
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Show Unread") {
                    NotificationCenter.default.post(name: .showUnreadRequested, object: nil)
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Show Starred") {
                    NotificationCenter.default.post(name: .showStarredRequested, object: nil)
                }
                .keyboardShortcut("3", modifiers: .command)
                
                Button("Show Recent") {
                    NotificationCenter.default.post(name: .showRecentRequested, object: nil)
                }
                .keyboardShortcut("4", modifiers: .command)
                
                Divider()
                
                Button("Focus Search") {
                    NotificationCenter.default.post(name: .focusSearchRequested, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
            
            // Article Menu
            CommandMenu("Article") {
                Button("Toggle Read Status") {
                    NotificationCenter.default.post(name: .toggleReadRequested, object: nil)
                }
                .keyboardShortcut("u", modifiers: .command)
                
                Button("Toggle Star") {
                    NotificationCenter.default.post(name: .toggleStarRequested, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Mark All as Read") {
                    NotificationCenter.default.post(name: .markAllReadRequested, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Open in Browser") {
                    NotificationCenter.default.post(name: .openInBrowserRequested, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Copy Article Link") {
                    NotificationCenter.default.post(name: .copyArticleLinkRequested, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                
                Button("Share...") {
                    NotificationCenter.default.post(name: .shareArticleRequested, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            
            // Feed Menu
            CommandMenu("Feed") {
                Button("Refresh All") {
                    NotificationCenter.default.post(name: .refreshAllRequested, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("Refresh Selected") {
                    NotificationCenter.default.post(name: .refreshSelectedRequested, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Edit Feed...") {
                    NotificationCenter.default.post(name: .editFeedRequested, object: nil)
                }
                .keyboardShortcut("e", modifiers: .command)
                
                Button("Delete Feed") {
                    NotificationCenter.default.post(name: .deleteFeedRequested, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: .command)
            }
            
            // Help Menu
            CommandGroup(after: .help) {
                Button("Keyboard Shortcuts") {
                    NotificationCenter.default.post(name: .showKeyboardShortcutsRequested, object: nil)
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView(settings: settings)
        }
    }
}

extension Notification.Name {
    // File menu
    static let addFeedRequested = Notification.Name("addFeedRequested")
    static let addFolderRequested = Notification.Name("addFolderRequested")
    static let importOPMLRequested = Notification.Name("importOPMLRequested")
    static let exportOPMLRequested = Notification.Name("exportOPMLRequested")
    
    // Edit menu
    static let selectAllArticlesRequested = Notification.Name("selectAllArticlesRequested")
    static let deselectAllRequested = Notification.Name("deselectAllRequested")
    
    // View menu
    static let showAllFeedsRequested = Notification.Name("showAllFeedsRequested")
    static let showUnreadRequested = Notification.Name("showUnreadRequested")
    static let showStarredRequested = Notification.Name("showStarredRequested")
    static let showRecentRequested = Notification.Name("showRecentRequested")
    static let focusSearchRequested = Notification.Name("focusSearchRequested")
    
    // Article menu
    static let toggleReadRequested = Notification.Name("toggleReadRequested")
    static let toggleStarRequested = Notification.Name("toggleStarRequested")
    static let markAllReadRequested = Notification.Name("markAllReadRequested")
    static let openInBrowserRequested = Notification.Name("openInBrowserRequested")
    static let copyArticleLinkRequested = Notification.Name("copyArticleLinkRequested")
    static let shareArticleRequested = Notification.Name("shareArticleRequested")
    
    // Feed menu
    static let refreshAllRequested = Notification.Name("refreshAllRequested")
    static let refreshSelectedRequested = Notification.Name("refreshSelectedRequested")
    static let editFeedRequested = Notification.Name("editFeedRequested")
    static let deleteFeedRequested = Notification.Name("deleteFeedRequested")
    
    // Help menu
    static let showKeyboardShortcutsRequested = Notification.Name("showKeyboardShortcutsRequested")
}
