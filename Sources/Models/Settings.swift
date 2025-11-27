//
//  Settings.swift
//  Sources
//
//  Created on November 26, 2025.
//

import Foundation

@Observable
class AppSettings {
    enum CacheSizeLimit: Int, CaseIterable {
        case mb50 = 50
        case mb100 = 100
        case mb200 = 200
        case mb500 = 500
        case gb1 = 1024
        case unlimited = -1
        
        var displayName: String {
            switch self {
            case .mb50: return "50 MB"
            case .mb100: return "100 MB"
            case .mb200: return "200 MB"
            case .mb500: return "500 MB"
            case .gb1: return "1 GB"
            case .unlimited: return "Unlimited"
            }
        }
        
        var bytes: Int64 {
            if self == .unlimited {
                return Int64.max
            }
            return Int64(rawValue) * 1024 * 1024
        }
    }
    
    enum CacheAge: Int, CaseIterable {
        case days7 = 7
        case days30 = 30
        case days90 = 90
        case never = -1
        
        var displayName: String {
            switch self {
            case .days7: return "7 days"
            case .days30: return "30 days"
            case .days90: return "90 days"
            case .never: return "Never"
            }
        }
        
        var timeInterval: TimeInterval? {
            if self == .never {
                return nil
            }
            return TimeInterval(rawValue * 24 * 60 * 60)
        }
    }
    
    enum ExcerptLength: Int, CaseIterable {
        case none = 0
        case oneLine = 1
        case twoLines = 2
        
        var displayName: String {
            switch self {
            case .none: return "None"
            case .oneLine: return "1 line"
            case .twoLines: return "2 lines"
            }
        }
    }
    
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
    
    var cacheSizeLimit: CacheSizeLimit {
        didSet {
            UserDefaults.standard.set(cacheSizeLimit.rawValue, forKey: "cacheSizeLimit")
        }
    }
    
    var cacheAge: CacheAge {
        didSet {
            UserDefaults.standard.set(cacheAge.rawValue, forKey: "cacheAge")
        }
    }
    
    var excerptLength: ExcerptLength {
        didSet {
            UserDefaults.standard.set(excerptLength.rawValue, forKey: "excerptLength")
        }
    }
    
    init() {
        self.autoRefreshEnabled = UserDefaults.standard.object(forKey: "autoRefreshEnabled") as? Bool ?? false
        self.refreshInterval = UserDefaults.standard.object(forKey: "refreshInterval") as? TimeInterval ?? 3600 // 1 hour default
        
        let cacheSizeValue = UserDefaults.standard.object(forKey: "cacheSizeLimit") as? Int ?? 100
        self.cacheSizeLimit = CacheSizeLimit(rawValue: cacheSizeValue) ?? .mb100
        
        let cacheAgeValue = UserDefaults.standard.object(forKey: "cacheAge") as? Int ?? 30
        self.cacheAge = CacheAge(rawValue: cacheAgeValue) ?? .days30
        
        let excerptValue = UserDefaults.standard.object(forKey: "excerptLength") as? Int ?? 2
        self.excerptLength = ExcerptLength(rawValue: excerptValue) ?? .twoLines
    }
    
    var refreshIntervalMinutes: Int {
        get { Int(refreshInterval / 60) }
        set { refreshInterval = TimeInterval(newValue * 60) }
    }
}
