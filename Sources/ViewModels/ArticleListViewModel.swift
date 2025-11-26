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
            articles = []
            return
        }
        
        // Get articles directly from the feed relationship
        var fetchedArticles = feed.articles
        
        // Sort based on selected order
        switch sortOrder {
        case .dateDescending:
            fetchedArticles.sort { $0.publishedDate > $1.publishedDate }
        case .dateAscending:
            fetchedArticles.sort { $0.publishedDate < $1.publishedDate }
        case .titleAscending:
            fetchedArticles.sort { $0.title < $1.title }
        }
        
        // Filter if needed
        if showUnreadOnly {
            fetchedArticles = fetchedArticles.filter { !$0.isRead }
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
}
