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
        let descriptor = FetchDescriptor<Article>(sortBy: [SortDescriptor(\.publishedDate, order: .reverse)])
        var fetchedArticles = (try? modelContext.fetch(descriptor)) ?? []
        
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
    
    func loadUnreadArticles() {
        let descriptor = FetchDescriptor<Article>(sortBy: [SortDescriptor(\.publishedDate, order: .reverse)])
        var fetchedArticles = (try? modelContext.fetch(descriptor)) ?? []
        
        // Filter unread only
        fetchedArticles = fetchedArticles.filter { !$0.isRead }
        
        // Filter by search text
        if !searchText.isEmpty {
            fetchedArticles = fetchedArticles.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.content.localizedCaseInsensitiveContains(searchText) ||
                (article.summary?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (article.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
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
    
    func loadRecentArticles() {
        let descriptor = FetchDescriptor<Article>(sortBy: [SortDescriptor(\.publishedDate, order: .reverse)])
        var fetchedArticles = (try? modelContext.fetch(descriptor)) ?? []
        
        // Filter by recency
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
        fetchedArticles = fetchedArticles.filter { $0.publishedDate >= startDate && $0.publishedDate <= endDate }
        
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
}
