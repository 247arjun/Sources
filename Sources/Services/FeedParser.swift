//
//  FeedParser.swift
//  Sources
//
//  Created on November 26, 2025.
//

import Foundation
import AppKit

struct ParsedFeed {
    let title: String
    let siteURL: URL?
    let description: String?
    let imageURL: URL?
    let articles: [ParsedArticle]
}

struct ParsedArticle {
    let id: String
    let title: String
    let author: String?
    let content: String
    let summary: String?
    let url: URL
    let publishedDate: Date
}

enum FeedParserError: Error {
    case invalidData
    case unsupportedFormat
    case parsingFailed(String)
}

class FeedParser: NSObject {
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentAuthor = ""
    private var currentContent = ""
    private var currentGuid = ""
    
    private var feedTitle = ""
    private var feedLink = ""
    private var feedDescription = ""
    private var feedImageURL = ""
    
    private var parsedArticles: [ParsedArticle] = []
    private var isParsingItem = false
    private var isAtomFeed = false
    
    func parse(data: Data) async throws -> ParsedFeed {
        // Execute XML parsing on a background thread to avoid blocking
        return try await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else {
                throw FeedParserError.parsingFailed("Parser deallocated")
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                let parser = XMLParser(data: data)
                parser.delegate = self
                
                // Reset state
                self.parsedArticles = []
                self.isParsingItem = false
                self.isAtomFeed = false
                self.feedTitle = ""
                self.feedLink = ""
                self.feedDescription = ""
                self.feedImageURL = ""
                
                if parser.parse() {
                    let feed = ParsedFeed(
                        title: self.feedTitle.isEmpty ? "Untitled Feed" : self.feedTitle,
                        siteURL: URL(string: self.feedLink),
                        description: self.feedDescription.isEmpty ? nil : self.feedDescription,
                        imageURL: self.feedImageURL.isEmpty ? nil : URL(string: self.feedImageURL),
                        articles: self.parsedArticles
                    )
                    continuation.resume(returning: feed)
                } else {
                    let error = parser.parserError ?? FeedParserError.parsingFailed("Unknown error")
                    continuation.resume(throwing: error)
                }
            }
        }.value
    }
}

extension FeedParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        
        // Detect Atom feed
        if elementName == "feed" && namespaceURI?.contains("atom") == true {
            isAtomFeed = true
        }
        
        // RSS item or Atom entry
        if elementName == "item" || elementName == "entry" {
            isParsingItem = true
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentPubDate = ""
            currentAuthor = ""
            currentContent = ""
            currentGuid = ""
        }
        
        // Link element - handle both Atom (href attribute) and RSS (text content)
        if elementName == "link" {
            if let href = attributeDict["href"] {
                // Atom style: <link href="URL" rel="alternate" />
                if isParsingItem {
                    // Only use alternate links for items
                    let rel = attributeDict["rel"] ?? "alternate"
                    if rel == "alternate" || rel == "self" {
                        currentLink = href
                    }
                } else {
                    feedLink = href
                }
            }
        }
        
        // Media content or enclosure
        if elementName == "enclosure" || elementName == "media:content" {
            if let url = attributeDict["url"], !isParsingItem {
                feedImageURL = url
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if isParsingItem {
            switch currentElement {
            case "title": currentTitle += trimmed
            case "link": currentLink += trimmed  // For RSS feeds that use text content
            case "description", "summary": currentDescription += trimmed
            case "content:encoded", "content": currentContent += trimmed
            case "pubDate", "published", "updated": currentPubDate += trimmed
            case "author", "dc:creator", "name": currentAuthor += trimmed
            case "guid", "id": currentGuid += trimmed
            default: break
            }
        } else {
            switch currentElement {
            case "title": feedTitle += trimmed
            case "link": feedLink += trimmed  // For RSS feeds that use text content
            case "description", "subtitle": feedDescription += trimmed
            case "url": feedImageURL += trimmed
            default: break
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" || elementName == "entry" {
            isParsingItem = false
            
            // Create article
            guard let url = URL(string: currentLink), !currentTitle.isEmpty else {
                return
            }
            
            let id = currentGuid.isEmpty ? currentLink : currentGuid
            let content = currentContent.isEmpty ? currentDescription : currentContent
            let publishedDate = parseDate(currentPubDate) ?? Date()
            
            let article = ParsedArticle(
                id: id,
                title: currentTitle.decodingHTMLEntities(),
                author: currentAuthor.isEmpty ? nil : currentAuthor.decodingHTMLEntities(),
                content: content,
                summary: currentDescription.isEmpty ? nil : currentDescription.decodingHTMLEntities(),
                url: url,
                publishedDate: publishedDate
            )
            
            parsedArticles.append(article)
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        // Try ISO8601 first
        let iso8601 = ISO8601DateFormatter()
        if let date = iso8601.date(from: dateString) {
            return date
        }
        
        // Try other formatters
        let formatters: [DateFormatter] = [
            rfc822DateFormatter(),
            rfc3339DateFormatter()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private func rfc822DateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
    
    private func rfc3339DateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
}

extension String {
    func decodingHTMLEntities() -> String {
        // Lightweight HTML entity decoder - much faster than NSAttributedString
        var result = self
        
        // Common HTML entities
        let entities: [(String, String)] = [
            ("&quot;", "\""),
            ("&apos;", "'"),
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&nbsp;", " "),
            ("&mdash;", "—"),
            ("&ndash;", "–"),
            ("&rsquo;", "'"),
            ("&lsquo;", "'"),
            ("&rdquo;", "\u{201D}"),
            ("&ldquo;", "\u{201C}"),
            ("&hellip;", "…"),
            ("&bull;", "•"),
            ("&middot;", "·")
        ]
        
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Decode numeric entities (&#123; and &#xAB;)
        result = result.replacingOccurrences(
            of: "&#(\\d+);",
            with: "$1",
            options: .regularExpression,
            range: nil
        )
        .replacingOccurrences(
            of: "&#x([0-9A-Fa-f]+);",
            with: "$1",
            options: .regularExpression,
            range: nil
        )
        
        return result
    }
}
