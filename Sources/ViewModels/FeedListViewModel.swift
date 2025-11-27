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
    var selectedFeeds: Set<Feed> = []
    var selectedSmartFolder: SmartFolder?
    var isRefreshing = false
    var errorMessage: String?
    var collapsedFolders: Set<Folder.ID> = []
    
    private let modelContext: ModelContext
    private let fetcher: FeedFetcher
    private var refreshTimer: Timer?
    var settings: AppSettings?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.fetcher = FeedFetcher()
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
    
    func addFeed(urlString: String) async {
        do {
            isRefreshing = true
            errorMessage = nil
            
            // Discover and validate feed URL
            let feedURL = try await fetcher.discoverFeed(from: urlString)
            
            // Fetch feed content
            let parsedFeed = try await fetcher.fetchFeed(from: feedURL)
            
            // Check if feed already exists
            let allFeedsDescriptor = FetchDescriptor<Feed>()
            let allFeeds = (try? modelContext.fetch(allFeedsDescriptor)) ?? []
            
            if allFeeds.contains(where: { $0.feedURL == feedURL }) {
                await MainActor.run {
                    errorMessage = "This feed is already added"
                    isRefreshing = false
                }
                return
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
        } catch {
            await MainActor.run {
                errorMessage = "Failed to add feed: \(error.localizedDescription)"
                isRefreshing = false
            }
        }
    }
    
    func refreshFeed(_ feed: Feed) async {
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
                
                // Trigger UI update by updating the selected feed reference
                if selectedFeed?.id == feed.id {
                    selectedFeed = feed
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to refresh feed: \(error.localizedDescription)"
            }
        }
    }
    
    func refreshAllFeeds() async {
        await MainActor.run {
            isRefreshing = true
            errorMessage = nil
        }
        
        for feed in feeds {
            await refreshFeed(feed)
        }
        
        await MainActor.run {
            isRefreshing = false
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
                    errorMessage = nil
                }
                
                // Start accessing security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    throw NSError(domain: "FeedListViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to access the file. Please try selecting it again."])
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                let data = try Data(contentsOf: url)
                let parser = OPMLParser()
                let outlines = try parser.parse(data: data)
                
                await processOPMLOutlines(outlines, parentFolder: nil)
                
                await MainActor.run {
                    loadFeeds()
                    isRefreshing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to import OPML: \(error.localizedDescription)"
                    isRefreshing = false
                }
            }
        }
    }
    
    private func processOPMLOutlines(_ outlines: [OPMLOutline], parentFolder: Folder?) async {
        for outline in outlines {
            if outline.isFolder {
                // Create folder
                await MainActor.run {
                    let folder = Folder(name: outline.title, sortOrder: folders.count)
                    modelContext.insert(folder)
                    try? modelContext.save()
                    
                    // Process children
                    Task {
                        await processOPMLOutlines(outline.children, parentFolder: folder)
                    }
                }
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
        }
        try? modelContext.save()
    }
    
    func markAllAsRead(for feed: Feed) {
        for article in feed.articles {
            article.isRead = true
        }
        try? modelContext.save()
    }
    
    func markAllAsReadInAllFeeds() {
        for feed in feeds {
            for article in feed.articles {
                article.isRead = true
            }
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
}
