//
//  Feed.swift
//  Sources
//
//  Created on November 26, 2025.
//

import Foundation
import SwiftData

@Model
final class Feed {
    var id: UUID
    var title: String
    var feedURL: URL
    var siteURL: URL?
    var feedDescription: String?
    var imageURL: URL?
    var lastUpdated: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Article.feed)
    var articles: [Article] = []
    
    var unreadCount: Int {
        articles.filter { !$0.isRead }.count
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        feedURL: URL,
        siteURL: URL? = nil,
        feedDescription: String? = nil,
        imageURL: URL? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.feedURL = feedURL
        self.siteURL = siteURL
        self.feedDescription = feedDescription
        self.imageURL = imageURL
        self.lastUpdated = lastUpdated
    }
}
