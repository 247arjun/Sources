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
                    
                    // AI Summary Section
                    AISummarySection(article: article, viewModel: viewModel)
                    
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
        // Try to load from cache first
        Task {
            let html = await loadContent()
            await MainActor.run {
                webView.loadHTMLString(html, baseURL: url)
            }
        }
    }
    
    private func loadContent() async -> String {
        // Create styled HTML wrapper
        let styledHTML = """
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
        
        // Generate article ID from URL
        let articleID = url.absoluteString
        
        // Check if already cached
        if let cached = await CacheManager.shared.getCachedArticle(id: articleID) {
            return cached
        }
        
        // Cache the content for next time
        try? await CacheManager.shared.cacheArticle(id: articleID, html: styledHTML)
        
        return styledHTML
    }
}

// MARK: - AI Summary Section

struct AISummarySection: View {
    let article: Article
    @Bindable var viewModel: ArticleListViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AI Summary", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.purple)
                
                Spacer()
                
                if article.aiSummary != nil {
                    Button(action: {
                        viewModel.clearSummary(for: article)
                    }) {
                        Label("Clear", systemImage: "xmark.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear AI summary")
                }
            }
            
            if let aiSummary = article.aiSummary {
                // Show existing summary
                VStack(alignment: .leading, spacing: 8) {
                    Text(aiSummary)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                    
                    if let generatedDate = article.aiSummaryGeneratedDate {
                        Text("Generated \(generatedDate, style: .relative)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
                
                Button(action: {
                    Task {
                        await viewModel.generateSummary(for: article)
                    }
                }) {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isSummarizing)
                
            } else if viewModel.isSummarizing {
                // Show loading state
                HStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Generating summary...")
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.05))
                .cornerRadius(8)
                
            } else if let error = viewModel.summarizationError {
                // Show error state
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.generateSummary(for: article)
                        }
                    }) {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
            } else if !viewModel.isSummarizationAvailable {
                // Show unavailable state
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.summarizationAvailabilityMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    
                    if viewModel.summarizationAvailabilityMessage.contains("Apple Intelligence") {
                        Button("Open Settings") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.Siri-Settings.extension") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
            } else {
                // Show generate button
                Button(action: {
                    Task {
                        await viewModel.generateSummary(for: article)
                    }
                }) {
                    Label("Generate Summary", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.purple)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}
