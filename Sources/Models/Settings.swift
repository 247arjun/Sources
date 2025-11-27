//
//  Settings.swift
//  Sources
//
//  Created on November 26, 2025.
//

import Foundation

@Observable
class AppSettings {
    var autoRefreshEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoRefreshEnabled, forKey: "autoRefreshEnabled")
        }
    }
    
    var refreshInterval: TimeInterval {
        didSet {
            UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
        }
    }
    
    init() {
        self.autoRefreshEnabled = UserDefaults.standard.object(forKey: "autoRefreshEnabled") as? Bool ?? false
        self.refreshInterval = UserDefaults.standard.object(forKey: "refreshInterval") as? TimeInterval ?? 3600 // 1 hour default
    }
    
    var refreshIntervalMinutes: Int {
        get { Int(refreshInterval / 60) }
        set { refreshInterval = TimeInterval(newValue * 60) }
    }
}
