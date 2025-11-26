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
                        feed: feedListViewModel.selectedFeed
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
            }
            if articleListViewModel == nil {
                articleListViewModel = ArticleListViewModel(modelContext: modelContext)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Feed.self, Article.self])
}
