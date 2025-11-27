//
//  Folder.swift
//  Sources
//
//  Created on November 26, 2025.
//

import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID
    var name: String
    var sortOrder: Int
    
    @Relationship(deleteRule: .nullify, inverse: \Feed.folder)
    var feeds: [Feed] = []
    
    var unreadCount: Int {
        feeds.reduce(0) { $0 + $1.unreadCount }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
    }
}
