//
//  Article.swift
//  Sources
//
//  Created on November 26, 2025.
//

import Foundation
import SwiftData

@Model
final class Article {
    var id: String
    var title: String
    var author: String?
    var content: String
    var summary: String?
    var url: URL
    var publishedDate: Date
    var isRead: Bool
    var isStarred: Bool
    
    var feed: Feed?
    
    init(
        id: String,
        title: String,
        author: String? = nil,
        content: String,
        summary: String? = nil,
        url: URL,
        publishedDate: Date,
        isRead: Bool = false,
        isStarred: Bool = false,
        feed: Feed? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.content = content
        self.summary = summary
        self.url = url
        self.publishedDate = publishedDate
        self.isRead = isRead
        self.isStarred = isStarred
        self.feed = feed
    }
}
