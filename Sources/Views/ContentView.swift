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
        mainContent
            .onAppear(perform: handleOnAppear)
            .onChange(of: settings.autoRefreshEnabled) { feedListViewModel?.setupAutoRefresh() }
            .onChange(of: settings.refreshInterval) { feedListViewModel?.setupAutoRefresh() }
            .onChange(of: settings.cacheSizeLimit) { Task { await performCacheMaintenance() } }
            .onChange(of: settings.cacheAge) { Task { await performCacheMaintenance() } }
            .modifier(ArticleNavigationModifier(viewModel: articleListViewModel))
            .modifier(ViewMenuModifier(viewModel: feedListViewModel))
            .modifier(ArticleActionModifier(viewModel: articleListViewModel))
            .modifier(FeedActionModifier(viewModel: feedListViewModel))
    }
    
    @ViewBuilder
    private var mainContent: some View {
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
                        feedListViewModel: feedListViewModel,
                        settings: settings
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
                    if newValue != nil {
                        feedListViewModel.selectedFolder = nil
                        feedListViewModel.selectedSmartFolder = nil
                    }
                    articleListViewModel.loadArticles(for: newValue)
                    articleListViewModel.selectedArticle = nil
                }
                .onChange(of: feedListViewModel.selectedSmartFolder) { oldValue, newValue in
                    if let smartFolder = newValue {
                        feedListViewModel.selectedFeed = nil
                        feedListViewModel.selectedFolder = nil
                        switch smartFolder {
                        case .allFeeds:
                            articleListViewModel.loadAllArticles()
                        case .unread:
                            articleListViewModel.loadUnreadArticles()
                        case .starred:
                            articleListViewModel.loadStarredArticles()
                        case .recent:
                            articleListViewModel.loadRecentArticles()
                        }
                        articleListViewModel.selectedArticle = nil
                    }
                }
                .onChange(of: feedListViewModel.selectedFolder) { oldValue, newValue in
                    if let folder = newValue {
                        feedListViewModel.selectedFeed = nil
                        feedListViewModel.selectedSmartFolder = nil
                        articleListViewModel.loadArticles(for: folder)
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
    }
    
    private func handleOnAppear() {
        if feedListViewModel == nil {
            feedListViewModel = FeedListViewModel(modelContext: modelContext)
            feedListViewModel?.loadFeeds()
            feedListViewModel?.startAutoRefresh(with: settings)
        }
        if articleListViewModel == nil {
            articleListViewModel = ArticleListViewModel(modelContext: modelContext)
        }
        
        Task {
            await performCacheMaintenance()
        }
    }
    
    private func performCacheMaintenance() async {
        // Clean up old cache based on age setting
        if let maxAge = settings.cacheAge.timeInterval {
            try? await CacheManager.shared.cleanupOldCache(olderThan: maxAge)
        }
        
        // Enforce size limit
        let sizeLimit = settings.cacheSizeLimit.bytes
        if sizeLimit > 0 {
            try? await CacheManager.shared.enforceSizeLimit(sizeLimit)
        }
    }
}

// MARK: - View Modifiers

struct ArticleNavigationModifier: ViewModifier {
    let viewModel: ArticleListViewModel?
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .toggleReadRequested)) { _ in
                if let article = viewModel?.selectedArticle {
                    viewModel?.toggleReadStatus(article)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleStarRequested)) { _ in
                if let article = viewModel?.selectedArticle {
                    viewModel?.toggleStarred(article)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openInBrowserRequested)) { _ in
                if let article = viewModel?.selectedArticle {
                    NSWorkspace.shared.open(article.url)
                }
            }
    }
}

struct ViewMenuModifier: ViewModifier {
    let viewModel: FeedListViewModel?
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .showAllFeedsRequested)) { _ in
                viewModel?.selectedSmartFolder = .allFeeds
                viewModel?.selectedFeed = nil
            }
            .onReceive(NotificationCenter.default.publisher(for: .showUnreadRequested)) { _ in
                viewModel?.selectedSmartFolder = .unread
                viewModel?.selectedFeed = nil
            }
            .onReceive(NotificationCenter.default.publisher(for: .showStarredRequested)) { _ in
                viewModel?.selectedSmartFolder = .starred
                viewModel?.selectedFeed = nil
            }
            .onReceive(NotificationCenter.default.publisher(for: .showRecentRequested)) { _ in
                viewModel?.selectedSmartFolder = .recent
                viewModel?.selectedFeed = nil
            }
    }
}

struct ArticleActionModifier: ViewModifier {
    let viewModel: ArticleListViewModel?
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .markAllReadRequested)) { _ in
                viewModel?.markAllAsRead()
            }
            .onReceive(NotificationCenter.default.publisher(for: .copyArticleLinkRequested)) { _ in
                if let article = viewModel?.selectedArticle {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(article.url.absoluteString, forType: .string)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .shareArticleRequested)) { _ in
                if let article = viewModel?.selectedArticle {
                    let picker = NSSharingServicePicker(items: [article.url])
                    if let view = NSApp.keyWindow?.contentView {
                        picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
                    }
                }
            }
    }
}

struct FeedActionModifier: ViewModifier {
    let viewModel: FeedListViewModel?
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .refreshAllRequested)) { _ in
                Task {
                    await viewModel?.refreshAllFeeds()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .refreshSelectedRequested)) { _ in
                if let feed = viewModel?.selectedFeed {
                    Task {
                        await viewModel?.refreshFeed(feed)
                    }
                }
            }
    }
}

#Preview {
    ContentView(settings: AppSettings())
        .modelContainer(for: [Feed.self, Article.self, Folder.self])
}
