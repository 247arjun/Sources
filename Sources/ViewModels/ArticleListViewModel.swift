//
//  ArticleListViewModel.swift
//  Sources
//
//  Created on November 26, 2025.
//

import Foundation
import SwiftData

@Observable
class ArticleListViewModel {
    var articles: [Article] = []
    var selectedArticle: Article?
    var sortOrder: SortOrder = .dateDescending
    var showUnreadOnly = false
    var searchText = ""
    var recencyFilter: RecencyFilter = .oneDay
    var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    var customEndDate: Date = Date()
    
    enum RecencyFilter: String, CaseIterable {
        case oneDay = "1 day"
        case sevenDays = "7 days"
        case custom = "Custom"
    }
    
    private let modelContext: ModelContext
    
    enum SortOrder {
        case dateDescending
        case dateAscending
        case titleAscending
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadArticles(for feed: Feed?) {
        guard let feed = feed else {
            loadAllArticles()
            return
        }
        
        // Get articles directly from the feed relationship
        var fetchedArticles = feed.articles
        
        // Filter by search text
        if !searchText.isEmpty {
            fetchedArticles = fetchedArticles.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.content.localizedCaseInsensitiveContains(searchText) ||
                (article.summary?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (article.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filter if needed
        if showUnreadOnly {
            fetchedArticles = fetchedArticles.filter { !$0.isRead }
        }
        
        // Sort based on selected order
        switch sortOrder {
        case .dateDescending:
            fetchedArticles.sort { $0.publishedDate > $1.publishedDate }
        case .dateAscending:
            fetchedArticles.sort { $0.publishedDate < $1.publishedDate }
        case .titleAscending:
            fetchedArticles.sort { $0.title < $1.title }
        }
        
        articles = fetchedArticles
    }
    
    func toggleReadStatus(_ article: Article) {
        article.isRead.toggle()
        try? modelContext.save()
    }
    
    func toggleStarred(_ article: Article) {
        article.isStarred.toggle()
        try? modelContext.save()
    }
    
    func markAsRead(_ article: Article) {
        article.isRead = true
        try? modelContext.save()
    }
    
    func markAllAsRead(for feed: Feed) {
        for article in feed.articles {
            article.isRead = true
        }
        try? modelContext.save()
        loadArticles(for: feed)
    }
    
    func markAllAsRead() {
        // Mark all currently displayed articles as read
        for article in articles {
            article.isRead = true
        }
        try? modelContext.save()
    }
    
    func selectNextArticle() {
        guard let currentArticle = selectedArticle,
              let currentIndex = articles.firstIndex(where: { $0.id == currentArticle.id }),
              currentIndex < articles.count - 1 else {
            // If no selection or at end, select first article
            selectedArticle = articles.first
            return
        }
        selectedArticle = articles[currentIndex + 1]
    }
    
    func selectPreviousArticle() {
        guard let currentArticle = selectedArticle,
              let currentIndex = articles.firstIndex(where: { $0.id == currentArticle.id }),
              currentIndex > 0 else {
            // If no selection or at start, select last article
            selectedArticle = articles.last
            return
        }
        selectedArticle = articles[currentIndex - 1]
    }
    
    func loadAllArticles() {
        // Build predicate for database-level filtering
        var predicate: Predicate<Article>?
        if showUnreadOnly {
            predicate = #Predicate<Article> { article in
                article.isRead == false
            }
        }
        
        // Build sort descriptor
        let sortDescriptor: SortDescriptor<Article>
        switch sortOrder {
        case .dateDescending:
            sortDescriptor = SortDescriptor(\.publishedDate, order: .reverse)
        case .dateAscending:
            sortDescriptor = SortDescriptor(\.publishedDate, order: .forward)
        case .titleAscending:
            sortDescriptor = SortDescriptor(\.title, order: .forward)
        }
        
        var descriptor = FetchDescriptor<Article>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )
        
        // Limit results for better performance (can load more on demand)
        descriptor.fetchLimit = 1000
        
        var fetchedArticles = (try? modelContext.fetch(descriptor)) ?? []
        
        // Only do in-memory search filtering as a fallback (database can't do case-insensitive contains efficiently)
        if !searchText.isEmpty {
            fetchedArticles = fetchedArticles.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.content.localizedCaseInsensitiveContains(searchText) ||
                (article.summary?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (article.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        articles = fetchedArticles
    }
    
    func loadUnreadArticles() {
        // Use database predicate for efficient filtering
        let predicate = #Predicate<Article> { article in
            article.isRead == false
        }
        
        // Build sort descriptor
        let sortDescriptor: SortDescriptor<Article>
        switch sortOrder {
        case .dateDescending:
            sortDescriptor = SortDescriptor(\.publishedDate, order: .reverse)
        case .dateAscending:
            sortDescriptor = SortDescriptor(\.publishedDate, order: .forward)
        case .titleAscending:
            sortDescriptor = SortDescriptor(\.title, order: .forward)
        }
        
        var descriptor = FetchDescriptor<Article>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )
        descriptor.fetchLimit = 1000
        
        var fetchedArticles = (try? modelContext.fetch(descriptor)) ?? []
        
        // Search filtering in memory
        if !searchText.isEmpty {
            fetchedArticles = fetchedArticles.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.content.localizedCaseInsensitiveContains(searchText) ||
                (article.summary?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (article.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        articles = fetchedArticles
    }
    
    func loadStarredArticles() {
        // Build predicate for starred articles
        var predicate: Predicate<Article>
        if showUnreadOnly {
            predicate = #Predicate<Article> { article in
                article.isStarred == true && article.isRead == false
            }
        } else {
            predicate = #Predicate<Article> { article in
                article.isStarred == true
            }
        }
        
        // Build sort descriptor
        let sortDescriptor: SortDescriptor<Article>
        switch sortOrder {
        case .dateDescending:
            sortDescriptor = SortDescriptor(\.publishedDate, order: .reverse)
        case .dateAscending:
            sortDescriptor = SortDescriptor(\.publishedDate, order: .forward)
        case .titleAscending:
            sortDescriptor = SortDescriptor(\.title, order: .forward)
        }
        
        var descriptor = FetchDescriptor<Article>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )
        descriptor.fetchLimit = 1000
        
        var fetchedArticles = (try? modelContext.fetch(descriptor)) ?? []
        
        // Search filtering in memory
        if !searchText.isEmpty {
            fetchedArticles = fetchedArticles.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.content.localizedCaseInsensitiveContains(searchText) ||
                (article.summary?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (article.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        articles = fetchedArticles
    }
    
    func loadRecentArticles() {
        // Calculate date range
        let now = Date()
        let startDate: Date
        
        switch recencyFilter {
        case .oneDay:
            startDate = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        case .sevenDays:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        case .custom:
            startDate = customStartDate
        }
        
        let endDate = recencyFilter == .custom ? customEndDate : now
        
        // Build predicate with date range filtering
        var predicate: Predicate<Article>
        if showUnreadOnly {
            predicate = #Predicate<Article> { article in
                article.publishedDate >= startDate && article.publishedDate <= endDate && article.isRead == false
            }
        } else {
            predicate = #Predicate<Article> { article in
                article.publishedDate >= startDate && article.publishedDate <= endDate
            }
        }
        
        // Build sort descriptor
        let sortDescriptor: SortDescriptor<Article>
        switch sortOrder {
        case .dateDescending:
            sortDescriptor = SortDescriptor(\.publishedDate, order: .reverse)
        case .dateAscending:
            sortDescriptor = SortDescriptor(\.publishedDate, order: .forward)
        case .titleAscending:
            sortDescriptor = SortDescriptor(\.title, order: .forward)
        }
        
        var descriptor = FetchDescriptor<Article>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )
        descriptor.fetchLimit = 1000
        
        var fetchedArticles = (try? modelContext.fetch(descriptor)) ?? []
        
        // Search filtering in memory
        if !searchText.isEmpty {
            fetchedArticles = fetchedArticles.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.content.localizedCaseInsensitiveContains(searchText) ||
                (article.summary?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (article.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        articles = fetchedArticles
    }
}
