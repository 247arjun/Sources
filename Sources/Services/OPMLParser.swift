//
//  OPMLParser.swift
//  Sources
//
//  Created on November 26, 2025.
//

import Foundation

struct OPMLOutline {
    let title: String
    let xmlUrl: String?
    let htmlUrl: String?
    let description: String?
    let children: [OPMLOutline]
    
    var isFolder: Bool {
        xmlUrl == nil && !children.isEmpty
    }
}

class OPMLParser: NSObject, XMLParserDelegate {
    private var outlines: [OPMLOutline] = []
    private var outlineStack: [(outline: OPMLOutline?, children: [OPMLOutline])] = [(nil, [])]
    
    func parse(data: Data) async throws -> [OPMLOutline] {
        // Execute XML parsing on a background thread to avoid blocking
        return try await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else {
                throw NSError(domain: "OPMLParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Parser deallocated"])
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                let parser = XMLParser(data: data)
                parser.delegate = self
                
                if parser.parse() {
                    continuation.resume(returning: self.outlines)
                } else {
                    let error = NSError(domain: "OPMLParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse OPML"])
                    continuation.resume(throwing: error)
                }
            }
        }.value
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "outline" {
            let title = attributeDict["text"] ?? attributeDict["title"] ?? "Untitled"
            let xmlUrl = attributeDict["xmlUrl"]
            let htmlUrl = attributeDict["htmlUrl"]
            let description = attributeDict["description"]
            
            let outline = OPMLOutline(
                title: title,
                xmlUrl: xmlUrl,
                htmlUrl: htmlUrl,
                description: description,
                children: []
            )
            
            // Push new outline context onto stack
            outlineStack.append((outline, []))
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "outline" {
            guard outlineStack.count > 1 else { return }
            
            // Pop the completed outline
            let (outline, children) = outlineStack.removeLast()
            
            // Create final outline with children
            if let outline = outline {
                let finalOutline = OPMLOutline(
                    title: outline.title,
                    xmlUrl: outline.xmlUrl,
                    htmlUrl: outline.htmlUrl,
                    description: outline.description,
                    children: children
                )
                
                // Add to parent's children or top-level
                if outlineStack.count > 1 {
                    outlineStack[outlineStack.count - 1].children.append(finalOutline)
                } else {
                    outlines.append(finalOutline)
                }
            }
        }
    }
}

class OPMLExporter {
    func export(feeds: [Feed], folders: [Folder]) -> String {
        var opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head>
                <title>Sources Feeds</title>
                <dateCreated>\(ISO8601DateFormatter().string(from: Date()))</dateCreated>
            </head>
            <body>
        
        """
        
        // Export folders with their feeds
        for folder in folders {
            opml += "        <outline text=\"\(folder.name.xmlEscaped)\">\n"
            for feed in folder.feeds.sorted(by: { $0.title < $1.title }) {
                opml += exportFeed(feed, indent: 3)
            }
            opml += "        </outline>\n"
        }
        
        // Export feeds without folders
        let unorganizedFeeds = feeds.filter { $0.folder == nil }.sorted(by: { $0.title < $1.title })
        for feed in unorganizedFeeds {
            opml += exportFeed(feed, indent: 2)
        }
        
        opml += """
            </body>
        </opml>
        """
        
        return opml
    }
    
    private func exportFeed(_ feed: Feed, indent: Int) -> String {
        let indentation = String(repeating: "    ", count: indent)
        var attributes = [
            "text=\"\(feed.title.xmlEscaped)\"",
            "type=\"rss\"",
            "xmlUrl=\"\(feed.feedURL.absoluteString.xmlEscaped)\""
        ]
        
        if let siteURL = feed.siteURL {
            attributes.append("htmlUrl=\"\(siteURL.absoluteString.xmlEscaped)\"")
        }
        
        if let description = feed.feedDescription {
            attributes.append("description=\"\(description.xmlEscaped)\"")
        }
        
        return "\(indentation)<outline \(attributes.joined(separator: " ")) />\n"
    }
}

extension String {
    var xmlEscaped: String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
