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
    var feeds: [Feed] = []
    var selectedFeed: Feed?
    var isRefreshing = false
    var errorMessage: String?
    
    private let modelContext: ModelContext
    private let fetcher: FeedFetcher
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.fetcher = FeedFetcher()
    }
    
    func loadFeeds() {
        let descriptor = FetchDescriptor<Feed>(sortBy: [SortDescriptor(\.title)])
        feeds = (try? modelContext.fetch(descriptor)) ?? []
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
}
