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
    var cachedUnreadCount: Int = 0
    
    @Relationship(deleteRule: .cascade, inverse: \Article.feed)
    var articles: [Article] = []
    
    var folder: Folder?
    
    var unreadCount: Int {
        cachedUnreadCount
    }
    
    func updateUnreadCount() {
        cachedUnreadCount = articles.filter { !$0.isRead }.count
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        feedURL: URL,
        siteURL: URL? = nil,
        feedDescription: String? = nil,
        imageURL: URL? = nil,
        lastUpdated: Date = Date(),
        folder: Folder? = nil
    ) {
        self.id = id
        self.title = title
        self.feedURL = feedURL
        self.siteURL = siteURL
        self.feedDescription = feedDescription
        self.imageURL = imageURL
        self.lastUpdated = lastUpdated
        self.folder = folder
        self.cachedUnreadCount = 0
    }
}
