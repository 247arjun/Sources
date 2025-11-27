//
//  ContentView.swift
//  Sources
//
//  Created on November 26, 2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var feedListViewModel: FeedListViewModel?
    @State private var articleListViewModel: ArticleListViewModel?
    var settings: AppSettings
    
    var body: some View {
        Group {
            if let feedListViewModel = feedListViewModel,
               let articleListViewModel = articleListViewModel {
                NavigationSplitView(
                    columnVisibility: .constant(.all)
                ) {
                    // Panel 1: Sidebar with feeds
                    SidebarView(viewModel: feedListViewModel)
                        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
                } content: {
                    // Panel 2: Article list
                    ArticleListView(
                        viewModel: articleListViewModel,
                        feed: feedListViewModel.selectedFeed,
                        feedListViewModel: feedListViewModel
                    )
                    .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 500)
                } detail: {
                    // Panel 3: Article detail with WebView
                    ArticleDetailView(
                        article: articleListViewModel.selectedArticle,
                        viewModel: articleListViewModel
                    )
                    .navigationSplitViewColumnWidth(min: 400, ideal: 600)
                }
                .onChange(of: feedListViewModel.selectedFeed) { oldValue, newValue in
                    articleListViewModel.loadArticles(for: newValue)
                    articleListViewModel.selectedArticle = nil
                }
                .onChange(of: feedListViewModel.selectedSmartFolder) { oldValue, newValue in
                    if let smartFolder = newValue {
                        feedListViewModel.selectedFeed = nil
                        switch smartFolder {
                        case .allFeeds:
                            articleListViewModel.loadAllArticles()
                        case .unread:
                            articleListViewModel.loadUnreadArticles()
                        case .recent:
                            articleListViewModel.loadRecentArticles()
                        }
                        articleListViewModel.selectedArticle = nil
                    }
                }
                .onAppear {
                    // Load articles for initially selected feed
                    if let selectedFeed = feedListViewModel.selectedFeed {
                        articleListViewModel.loadArticles(for: selectedFeed)
                    }
                }
            }
        }
        .onAppear {
            if feedListViewModel == nil {
                feedListViewModel = FeedListViewModel(modelContext: modelContext)
                feedListViewModel?.loadFeeds()
                feedListViewModel?.startAutoRefresh(with: settings)
            }
            if articleListViewModel == nil {
                articleListViewModel = ArticleListViewModel(modelContext: modelContext)
            }
        }
        .onChange(of: settings.autoRefreshEnabled) {
            feedListViewModel?.setupAutoRefresh()
        }
        .onChange(of: settings.refreshInterval) {
            feedListViewModel?.setupAutoRefresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .nextArticleRequested)) { _ in
            articleListViewModel?.selectNextArticle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .previousArticleRequested)) { _ in
            articleListViewModel?.selectPreviousArticle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleReadRequested)) { _ in
            if let article = articleListViewModel?.selectedArticle {
                articleListViewModel?.toggleReadStatus(article)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openInBrowserRequested)) { _ in
            if let article = articleListViewModel?.selectedArticle {
                NSWorkspace.shared.open(article.url)
            }
        }
    }
}

#Preview {
    ContentView(settings: AppSettings())
        .modelContainer(for: [Feed.self, Article.self, Folder.self])
}
