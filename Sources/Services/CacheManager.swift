//
//  CacheManager.swift
//  Sources
//
//  Created on November 26, 2025.
//

import Foundation
import CryptoKit

actor CacheManager {
    static let shared = CacheManager()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let metadataFile: URL
    
    struct CacheMetadata: Codable {
        var entries: [String: CacheEntry] = [:]
        var totalSize: Int64 = 0
        var lastCleanup: Date = Date()
    }
    
    struct CacheEntry: Codable {
        let articleID: String
        let cachedDate: Date
        let size: Int64
        let contentHash: String
    }
    
    private var metadata: CacheMetadata
    
    init() {
        // Get Application Support directory
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "com.sources.app"
        let appDirectory = appSupport.appendingPathComponent(bundleID)
        
        // Create cache directory
        self.cacheDirectory = appDirectory.appendingPathComponent("ArticleCache")
        self.metadataFile = appDirectory.appendingPathComponent("cache-metadata.json")
        
        // Load or initialize metadata
        if let data = try? Data(contentsOf: metadataFile),
           let meta = try? JSONDecoder().decode(CacheMetadata.self, from: data) {
            self.metadata = meta
        } else {
            self.metadata = CacheMetadata()
        }
        
        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Cache Operations
    
    func cacheArticle(id: String, html: String) async throws {
        let hash = Self.hashString(id)
        let fileURL = cacheDirectory.appendingPathComponent(hash + ".html")
        
        guard let data = html.data(using: .utf8) else {
            throw CacheError.invalidData
        }
        
        try data.write(to: fileURL)
        
        let size = Int64(data.count)
        let entry = CacheEntry(
            articleID: id,
            cachedDate: Date(),
            size: size,
            contentHash: Self.hashString(html)
        )
        
        metadata.entries[hash] = entry
        metadata.totalSize += size
        
        try await saveMetadata()
    }
    
    func getCachedArticle(id: String) async -> String? {
        let hash = Self.hashString(id)
        let fileURL = cacheDirectory.appendingPathComponent(hash + ".html")
        
        guard let data = try? Data(contentsOf: fileURL),
              let html = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return html
    }
    
    func isCached(articleID: String) async -> Bool {
        let hash = Self.hashString(articleID)
        return metadata.entries[hash] != nil
    }
    
    // MARK: - Cache Management
    
    func clearCache() async throws {
        // Remove all cached files
        if fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.removeItem(at: cacheDirectory)
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        // Reset metadata
        metadata = CacheMetadata()
        try await saveMetadata()
    }
    
    func cleanupOldCache(olderThan timeInterval: TimeInterval?) async throws {
        guard let timeInterval = timeInterval else { return }
        
        let cutoffDate = Date().addingTimeInterval(-timeInterval)
        var removedSize: Int64 = 0
        var keysToRemove: [String] = []
        
        for (hash, entry) in metadata.entries {
            if entry.cachedDate < cutoffDate {
                let fileURL = cacheDirectory.appendingPathComponent(hash + ".html")
                try? fileManager.removeItem(at: fileURL)
                removedSize += entry.size
                keysToRemove.append(hash)
            }
        }
        
        for key in keysToRemove {
            metadata.entries.removeValue(forKey: key)
        }
        
        metadata.totalSize -= removedSize
        metadata.lastCleanup = Date()
        
        try await saveMetadata()
    }
    
    func enforceSizeLimit(_ limit: Int64) async throws {
        guard limit > 0 && metadata.totalSize > limit else { return }
        
        // Sort entries by date (oldest first)
        let sortedEntries = metadata.entries.sorted { $0.value.cachedDate < $1.value.cachedDate }
        
        var removedSize: Int64 = 0
        var keysToRemove: [String] = []
        
        for (hash, entry) in sortedEntries {
            if metadata.totalSize - removedSize <= limit {
                break
            }
            
            let fileURL = cacheDirectory.appendingPathComponent(hash + ".html")
            try? fileManager.removeItem(at: fileURL)
            removedSize += entry.size
            keysToRemove.append(hash)
        }
        
        for key in keysToRemove {
            metadata.entries.removeValue(forKey: key)
        }
        
        metadata.totalSize -= removedSize
        
        try await saveMetadata()
    }
    
    // MARK: - Statistics
    
    func getCacheStats() async -> (size: Int64, count: Int, lastCleanup: Date) {
        return (metadata.totalSize, metadata.entries.count, metadata.lastCleanup)
    }
    
    func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Private Helpers
    
    private func saveMetadata() async throws {
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataFile)
    }
    
    private static func hashString(_ string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum CacheError: LocalizedError {
    case invalidData
    case fileNotFound
    case writeError
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data for caching"
        case .fileNotFound:
            return "Cached file not found"
        case .writeError:
            return "Failed to write cache file"
        }
    }
}
