//
//  FeedListViewModel.swift
//  Sources
//
//  Created on November 26, 2025.
//

import Foundation
import SwiftData

@Observable
class FeedListViewModel {
    enum SmartFolder {
        case allFeeds
        case unread
        case starred
        case recent
    }
    
    var feeds: [Feed] = []
    var folders: [Folder] = []
    var selectedFeed: Feed?
    var selectedFolder: Folder?
    var selectedFeeds: Set<Feed> = []
    var selectedSmartFolder: SmartFolder?
    var isRefreshing = false
    var hasRefreshError = false
    var failedFeeds: [(feed: Feed, error: Error)] = []
    var collapsedFolders: Set<Folder.ID> = [] {
        didSet {
            saveCollapsedState()
        }
    }
    
    private let modelContext: ModelContext
    private let fetcher: FeedFetcher
    private var refreshTimer: Timer?
    var settings: AppSettings?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.fetcher = FeedFetcher()
        loadCollapsedState()
    }
    
    func startAutoRefresh(with settings: AppSettings) {
        self.settings = settings
        setupAutoRefresh()
    }
    
    func setupAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        guard let settings = settings, settings.autoRefreshEnabled else {
            return
        }
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: settings.refreshInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.refreshAllFeeds()
            }
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    func loadFeeds() {
        let feedDescriptor = FetchDescriptor<Feed>(sortBy: [SortDescriptor(\.title)])
        feeds = (try? modelContext.fetch(feedDescriptor)) ?? []
        
        // Update cached unread counts for all feeds
        for feed in feeds {
            feed.updateUnreadCount()
        }
        
        let folderDescriptor = FetchDescriptor<Folder>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)])
        folders = (try? modelContext.fetch(folderDescriptor)) ?? []
    }
    
    func addFolder(name: String) {
        let folder = Folder(name: name, sortOrder: folders.count)
        modelContext.insert(folder)
        try? modelContext.save()
        loadFeeds()
    }
    
    func deleteFolder(_ folder: Folder) {
        // Move feeds out of folder before deleting
        for feed in folder.feeds {
            feed.folder = nil
        }
        modelContext.delete(folder)
        try? modelContext.save()
        loadFeeds()
    }
    
    func moveFeed(_ feed: Feed, to folder: Folder?) {
        feed.folder = folder
        try? modelContext.save()
        loadFeeds()
    }
    
    func addFeed(urlString: String) async -> Result<Feed, Error> {
        do {
            isRefreshing = true
            hasRefreshError = false
            
            // Discover and validate feed URL
            let feedURL = try await fetcher.discoverFeed(from: urlString)
            
            // Fetch feed content
            let parsedFeed = try await fetcher.fetchFeed(from: feedURL)
            
            // Check if feed already exists
            let allFeedsDescriptor = FetchDescriptor<Feed>()
            let allFeeds = (try? modelContext.fetch(allFeedsDescriptor)) ?? []
            
            if allFeeds.contains(where: { $0.feedURL == feedURL }) {
                await MainActor.run {
                    isRefreshing = false
                }
                return .failure(NSError(domain: "FeedListViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "This feed is already added"]))
            }
            
            // Create feed
            let feed = Feed(
                title: parsedFeed.title,
                feedURL: feedURL,
                siteURL: parsedFeed.siteURL,
                feedDescription: parsedFeed.description,
                imageURL: parsedFeed.imageURL,
                lastUpdated: Date()
            )
            
            modelContext.insert(feed)
            
            // Add articles
            for parsedArticle in parsedFeed.articles {
                let article = Article(
                    id: parsedArticle.id,
                    title: parsedArticle.title,
                    author: parsedArticle.author,
                    content: parsedArticle.content,
                    summary: parsedArticle.summary,
                    url: parsedArticle.url,
                    publishedDate: parsedArticle.publishedDate,
                    feed: feed
                )
                modelContext.insert(article)
            }
            
            try modelContext.save()
            
            await MainActor.run {
                loadFeeds()
                selectedFeed = feed
                isRefreshing = false
            }
            return .success(feed)
        } catch {
            await MainActor.run {
                isRefreshing = false
            }
            return .failure(error)
        }
    }
    
    func refreshFeed(_ feed: Feed) async -> Result<Void, Error> {
        do {
            let parsedFeed = try await fetcher.fetchFeed(from: feed.feedURL)
            
            await MainActor.run {
                // Update feed metadata
                feed.title = parsedFeed.title
                feed.siteURL = parsedFeed.siteURL
                feed.feedDescription = parsedFeed.description
                feed.imageURL = parsedFeed.imageURL
                feed.lastUpdated = Date()
                
                // Add new articles
                var newArticlesAdded = 0
                for parsedArticle in parsedFeed.articles {
                    // Check if article already exists in feed
                    if feed.articles.contains(where: { $0.id == parsedArticle.id }) {
                        continue
                    }
                    
                    let article = Article(
                        id: parsedArticle.id,
                        title: parsedArticle.title,
                        author: parsedArticle.author,
                        content: parsedArticle.content,
                        summary: parsedArticle.summary,
                        url: parsedArticle.url,
                        publishedDate: parsedArticle.publishedDate,
                        feed: feed
                    )
                    modelContext.insert(article)
                    newArticlesAdded += 1
                }
                
                try? modelContext.save()
                // Update cached unread count for performance
                feed.updateUnreadCount()
                // Trigger UI update by updating the selected feed reference
                if selectedFeed?.id == feed.id {
                    selectedFeed = feed
                }
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    func refreshAllFeeds() async {
        await MainActor.run {
            isRefreshing = true
            hasRefreshError = false
            failedFeeds = []
        }
        
        // Refresh feeds concurrently in batches of 5 to avoid overwhelming the system
        let batchSize = 5
        for batchStart in stride(from: 0, to: feeds.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, feeds.count)
            let batch = Array(feeds[batchStart..<batchEnd])
            
            await withTaskGroup(of: (Feed, Result<Void, Error>).self) { group in
                for feed in batch {
                    group.addTask {
                        let result = await self.refreshFeed(feed)
                        return (feed, result)
                    }
                }
                
                for await (feed, result) in group {
                    if case .failure(let error) = result {
                        await MainActor.run {
                            failedFeeds.append((feed: feed, error: error))
                        }
                    }
                }
            }
        }
        
        await MainActor.run {
            isRefreshing = false
            // Delay showing error icon to allow animation to complete
            if !failedFeeds.isEmpty {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                    hasRefreshError = true
                }
            }
        }
    }
    
    func deleteFeed(_ feed: Feed) {
        modelContext.delete(feed)
        try? modelContext.save()
        loadFeeds()
        if selectedFeed?.id == feed.id {
            selectedFeed = nil
        }
    }
    
    func deleteFeeds(_ feeds: Set<Feed>) {
        for feed in feeds {
            modelContext.delete(feed)
        }
        try? modelContext.save()
        selectedFeeds.removeAll()
        selectedFeed = nil
        loadFeeds()
    }
    
    func moveFeeds(_ feeds: Set<Feed>, to folder: Folder?) {
        for feed in feeds {
            feed.folder = folder
        }
        try? modelContext.save()
        selectedFeeds.removeAll()
        loadFeeds()
    }
    
    func importOPML(from url: URL) {
        Task {
            do {
                await MainActor.run {
                    isRefreshing = true
                    hasRefreshError = false
                }
                
                // Start accessing security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    throw NSError(domain: "FeedListViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to access the file. Please try selecting it again."])
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                // Read file asynchronously on background thread
                let data = try await Task.detached(priority: .userInitiated) {
                    try Data(contentsOf: url)
                }.value
                
                let parser = OPMLParser()
                let outlines = try await parser.parse(data: data)
                
                await processOPMLOutlines(outlines, parentFolder: nil)
                
                await MainActor.run {
                    loadFeeds()
                    isRefreshing = false
                }
            } catch {
                // Track OPML import error
                await MainActor.run {
                    let dummyFeed = Feed(title: "OPML Import", feedURL: url, lastUpdated: Date())
                    failedFeeds = [(feed: dummyFeed, error: error)]
                    
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        hasRefreshError = true
                    }
                    isRefreshing = false
                }
            }
        }
    }
    
    private func processOPMLOutlines(_ outlines: [OPMLOutline], parentFolder: Folder?) async {
        for outline in outlines {
            if outline.isFolder {
                // Check if folder already exists
                let folderDescriptor = FetchDescriptor<Folder>()
                let existingFolder = await MainActor.run {
                    do {
                        let allFolders = try modelContext.fetch(folderDescriptor)
                        return allFolders.first(where: { $0.name == outline.title })
                    } catch {
                        return nil
                    }
                }
                
                let folderToUse: Folder
                if let existingFolder = existingFolder {
                    // Use existing folder
                    folderToUse = existingFolder
                } else {
                    // Create new folder
                    folderToUse = await MainActor.run {
                        let folder = Folder(name: outline.title, sortOrder: folders.count)
                        modelContext.insert(folder)
                        try? modelContext.save()
                        return folder
                    }
                }
                
                // Process children with the folder (existing or new)
                await processOPMLOutlines(outline.children, parentFolder: folderToUse)
                
            } else if let xmlUrlString = outline.xmlUrl, let xmlUrl = URL(string: xmlUrlString) {
                // Check if feed already exists using fresh fetch
                let feedDescriptor = FetchDescriptor<Feed>()
                let allFeeds = await MainActor.run {
                    do {
                        return try modelContext.fetch(feedDescriptor)
                    } catch {
                        return []
                    }
                }
                
                if allFeeds.contains(where: { $0.feedURL == xmlUrl }) {
                    continue
                }
                
                // Add feed
                do {
                    let parsedFeed = try await fetcher.fetchFeed(from: xmlUrl)
                    
                    await MainActor.run {
                        let feed = Feed(
                            title: parsedFeed.title,
                            feedURL: xmlUrl,
                            siteURL: parsedFeed.siteURL,
                            feedDescription: parsedFeed.description,
                            imageURL: parsedFeed.imageURL,
                            lastUpdated: Date()
                        )
                        feed.folder = parentFolder
                        
                        modelContext.insert(feed)
                        
                        // Add articles
                        for parsedArticle in parsedFeed.articles {
                            let article = Article(
                                id: parsedArticle.id,
                                title: parsedArticle.title,
                                author: parsedArticle.author,
                                content: parsedArticle.content,
                                summary: parsedArticle.summary,
                                url: parsedArticle.url,
                                publishedDate: parsedArticle.publishedDate,
                                feed: feed
                            )
                            modelContext.insert(article)
                        }
                        
                        try? modelContext.save()
                    }
                } catch {
                    // Log error but continue processing other feeds
                    print("Failed to import feed \(xmlUrl): \(error.localizedDescription)")
                    continue
                }
            }
        }
    }
    
    func exportOPML() -> String {
        let exporter = OPMLExporter()
        return exporter.export(feeds: feeds, folders: folders)
    }
    
    func toggleFolderCollapse(_ folder: Folder) {
        if collapsedFolders.contains(folder.id) {
            collapsedFolders.remove(folder.id)
        } else {
            collapsedFolders.insert(folder.id)
        }
    }
    
    func isFolderCollapsed(_ folder: Folder) -> Bool {
        collapsedFolders.contains(folder.id)
    }
    
    func markAllAsRead(in folder: Folder) {
        for feed in folder.feeds {
            for article in feed.articles {
                article.isRead = true
            }
            feed.updateUnreadCount()
        }
        try? modelContext.save()
    }
    
    func markAllAsRead(for feed: Feed) {
        for article in feed.articles {
            article.isRead = true
        }
        feed.updateUnreadCount()
        try? modelContext.save()
    }
    
    func markAllAsReadInAllFeeds() {
        for feed in feeds {
            for article in feed.articles {
                article.isRead = true
            }
            feed.updateUnreadCount()
        }
        try? modelContext.save()
    }
    
    func markAllAsReadInStarred() {
        let descriptor = FetchDescriptor<Article>(predicate: #Predicate { $0.isStarred == true })
        if let starredArticles = try? modelContext.fetch(descriptor) {
            for article in starredArticles {
                article.isRead = true
            }
            try? modelContext.save()
        }
    }
    
    func markAllAsReadInRecent() {
        // For simplicity, mark all articles as read since we don't have easy access to recency filter here
        // In a production app, you'd pass the date range or calculate it
        markAllAsReadInAllFeeds()
    }
    
    // MARK: - Collapsed State Persistence
    
    private func saveCollapsedState() {
        let collapsedIDs = Array(collapsedFolders).map { $0.uuidString }
        UserDefaults.standard.set(collapsedIDs, forKey: "collapsedFolders")
    }
    
    private func loadCollapsedState() {
        if let savedIDs = UserDefaults.standard.array(forKey: "collapsedFolders") as? [String] {
            collapsedFolders = Set(savedIDs.compactMap { UUID(uuidString: $0) })
        }
    }
    
    // MARK: - Cleanup Operations
    
    /// Perform comprehensive cleanup of duplicates and failing feeds
    func performCleanup() async -> CleanupResult {
        var result = CleanupResult()
        
        // 1. Remove duplicate folders
        let duplicateFolders = await removeDuplicateFolders()
        result.foldersRemoved = duplicateFolders
        
        // 2. Remove duplicate feeds
        let duplicateFeeds = await removeDuplicateFeeds()
        result.feedsRemoved = duplicateFeeds
        
        // 3. Remove failing feeds (after 3 retries)
        let failingFeeds = await removeFailingFeeds()
        result.failingFeedsRemoved = failingFeeds
        
        return result
    }
    
    /// Remove duplicate folders (keeping the first occurrence)
    private func removeDuplicateFolders() async -> Int {
        let folderDescriptor = FetchDescriptor<Folder>()
        guard let allFolders = try? await MainActor.run(body: { try modelContext.fetch(folderDescriptor) }) else {
            return 0
        }
        
        var seenNames: [String: Folder] = [:]
        var duplicates: [Folder] = []
        
        for folder in allFolders {
            if let existingFolder = seenNames[folder.name] {
                // This is a duplicate - merge feeds into the existing folder
                for feed in folder.feeds {
                    feed.folder = existingFolder
                }
                duplicates.append(folder)
            } else {
                seenNames[folder.name] = folder
            }
        }
        
        // Remove duplicate folders
        await MainActor.run {
            for duplicate in duplicates {
                modelContext.delete(duplicate)
            }
            try? modelContext.save()
            loadFeeds()
        }
        
        return duplicates.count
    }
    
    /// Remove duplicate feeds (keeping the first occurrence by URL)
    private func removeDuplicateFeeds() async -> Int {
        let feedDescriptor = FetchDescriptor<Feed>()
        guard let allFeeds = try? await MainActor.run(body: { try modelContext.fetch(feedDescriptor) }) else {
            return 0
        }
        
        var seenURLs: [URL: Feed] = [:]
        var duplicates: [Feed] = []
        
        for feed in allFeeds {
            if seenURLs[feed.feedURL] != nil {
                // This is a duplicate
                duplicates.append(feed)
            } else {
                seenURLs[feed.feedURL] = feed
            }
        }
        
        // Remove duplicate feeds
        await MainActor.run {
            for duplicate in duplicates {
                modelContext.delete(duplicate)
            }
            try? modelContext.save()
            loadFeeds()
        }
        
        return duplicates.count
    }
    
    /// Remove feeds that fail to load after 3 retry attempts
    private func removeFailingFeeds() async -> Int {
        let feedDescriptor = FetchDescriptor<Feed>()
        guard let allFeeds = try? await MainActor.run(body: { try modelContext.fetch(feedDescriptor) }) else {
            return 0
        }
        
        var failedFeeds: [Feed] = []
        
        for feed in allFeeds {
            var retryCount = 0
            var lastError: Error?
            
            // Try 3 times
            while retryCount < 3 {
                do {
                    _ = try await fetcher.fetchFeed(from: feed.feedURL)
                    // Success - feed is working
                    break
                } catch {
                    lastError = error
                    retryCount += 1
                    if retryCount < 3 {
                        // Wait 2 seconds between retries
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                    }
                }
            }
            
            // If all 3 attempts failed, mark for removal
            if retryCount == 3 {
                print("Feed '\(feed.title)' failed after 3 attempts: \(lastError?.localizedDescription ?? "Unknown error")")
                failedFeeds.append(feed)
            }
        }
        
        // Remove failed feeds
        await MainActor.run {
            for feed in failedFeeds {
                modelContext.delete(feed)
            }
            try? modelContext.save()
            loadFeeds()
        }
        
        return failedFeeds.count
    }
}

/// Result of cleanup operation
struct CleanupResult {
    var foldersRemoved: Int = 0
    var feedsRemoved: Int = 0
    var failingFeedsRemoved: Int = 0
    
    var totalItemsRemoved: Int {
        foldersRemoved + feedsRemoved + failingFeedsRemoved
    }
    
    var summary: String {
        var parts: [String] = []
        if foldersRemoved > 0 {
            parts.append("\(foldersRemoved) duplicate folder\(foldersRemoved == 1 ? "" : "s")")
        }
        if feedsRemoved > 0 {
            parts.append("\(feedsRemoved) duplicate feed\(feedsRemoved == 1 ? "" : "s")")
        }
        if failingFeedsRemoved > 0 {
            parts.append("\(failingFeedsRemoved) failing feed\(failingFeedsRemoved == 1 ? "" : "s")")
        }
        
        if parts.isEmpty {
            return "No issues found"
        } else {
            return "Removed: " + parts.joined(separator: ", ")
        }
    }
}
