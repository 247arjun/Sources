//
//  FeedFetcher.swift
//  Sources
//
//  Created on November 26, 2025.
//

import Foundation

enum FetchError: Error {
    case invalidURL
    case networkError(Error)
    case httpError(statusCode: Int)
    case noData
}

actor FeedFetcher {
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.httpAdditionalHeaders = [
            "User-Agent": "Sources/1.0"
        ]
        self.session = URLSession(configuration: config)
    }
    
    func fetchFeed(from url: URL) async throws -> ParsedFeed {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FetchError.networkError(NSError(domain: "Invalid response", code: -1))
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw FetchError.httpError(statusCode: httpResponse.statusCode)
        }
        
        guard !data.isEmpty else {
            throw FetchError.noData
        }
        
        let parser = FeedParser()
        return try await parser.parse(data: data)
    }
    
    func discoverFeed(from urlString: String) async throws -> URL {
        // Clean and validate URL
        var cleanURL = urlString.trimmingCharacters(in: .whitespaces)
        if !cleanURL.hasPrefix("http://") && !cleanURL.hasPrefix("https://") {
            cleanURL = "https://" + cleanURL
        }
        
        guard let url = URL(string: cleanURL) else {
            throw FetchError.invalidURL
        }
        
        // Try the URL directly first
        do {
            _ = try await fetchFeed(from: url)
            return url
        } catch {
            // If direct fetch fails, try to discover feed URL from the page
            return try await discoverFromWebpage(url)
        }
    }
    
    private func discoverFromWebpage(_ url: URL) async throws -> URL {
        let (data, _) = try await session.data(from: url)
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw FetchError.invalidURL
        }
        
        // Look for common feed URL patterns
        let patterns = [
            #"<link[^>]+type=["\']application/rss\+xml["\'][^>]+href=["\']([^"\']+)["\']"#,
            #"<link[^>]+type=["\']application/atom\+xml["\'][^>]+href=["\']([^"\']+)["\']"#,
            #"<link[^>]+href=["\']([^"\']+)["\'][^>]+type=["\']application/rss\+xml["\']"#,
            #"<link[^>]+href=["\']([^"\']+)["\'][^>]+type=["\']application/atom\+xml["\']"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let feedURLString = String(html[range])
                
                // Handle relative URLs
                if let feedURL = URL(string: feedURLString, relativeTo: url)?.absoluteURL {
                    return feedURL
                }
            }
        }
        
        // Try common feed locations
        let commonPaths = ["/feed", "/rss", "/feed.xml", "/rss.xml", "/atom.xml"]
        for path in commonPaths {
            if let feedURL = URL(string: path, relativeTo: url)?.absoluteURL {
                do {
                    _ = try await fetchFeed(from: feedURL)
                    return feedURL
                } catch {
                    continue
                }
            }
        }
        
        throw FetchError.invalidURL
    }
}
