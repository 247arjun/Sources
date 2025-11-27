//
//  ArticleDetailView.swift
//  Sources
//
//  Created on November 26, 2025.
//

import SwiftUI
import WebKit

struct ArticleDetailView: View {
    let article: Article?
    @Bindable var viewModel: ArticleListViewModel
    
    var body: some View {
        Group {
            if let article = article {
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(article.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            if let author = article.author {
                                Text("By \(author)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("•")
                                .foregroundStyle(.secondary)
                            
                            Text(article.publishedDate, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.background)
                    
                    Divider()
                    
                    // WebView
                    WebView(url: article.url, content: article.content)
                        .onAppear {
                            if !article.isRead {
                                viewModel.markAsRead(article)
                            }
                        }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            viewModel.toggleReadStatus(article)
                        }) {
                            Label(
                                article.isRead ? "Mark as Unread" : "Mark as Read",
                                systemImage: article.isRead ? "circle" : "checkmark.circle.fill"
                            )
                        }
                    }
                    
                    ToolbarItem(placement: .automatic) {
                        Button(action: {
                            viewModel.toggleStarred(article)
                        }) {
                            Label(
                                article.isStarred ? "Unstar" : "Star",
                                systemImage: article.isStarred ? "star.fill" : "star"
                            )
                        }
                        .foregroundStyle(article.isStarred ? .yellow : .primary)
                    }
                    
                    ToolbarItem(placement: .automatic) {
                        ShareLink(item: article.url) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                    ToolbarItem(placement: .automatic) {
                        Button(action: {
                            NSWorkspace.shared.open(article.url)
                        }) {
                            Label("Open in Browser", systemImage: "safari")
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Article Selected",
                    systemImage: "doc.text",
                    description: Text("Select an article to read")
                )
            }
        }
    }
}

struct WebView: NSViewRepresentable {
    let url: URL
    let content: String
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        // Create HTML wrapper with styling
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                    font-size: 16px;
                    line-height: 1.6;
                    color: #333;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 20px;
                }
                @media (prefers-color-scheme: dark) {
                    body {
                        background-color: #1e1e1e;
                        color: #e0e0e0;
                    }
                    a {
                        color: #6eb3ff;
                    }
                }
                img {
                    max-width: 100%;
                    height: auto;
                }
                pre {
                    background-color: #f5f5f5;
                    padding: 10px;
                    border-radius: 5px;
                    overflow-x: auto;
                }
                @media (prefers-color-scheme: dark) {
                    pre {
                        background-color: #2d2d2d;
                    }
                }
                blockquote {
                    border-left: 4px solid #ddd;
                    padding-left: 16px;
                    margin-left: 0;
                    color: #666;
                }
                @media (prefers-color-scheme: dark) {
                    blockquote {
                        border-left-color: #555;
                        color: #aaa;
                    }
                }
            </style>
        </head>
        <body>
            \(content)
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: url)
    }
}
