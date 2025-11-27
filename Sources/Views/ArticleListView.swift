//
//  ArticleListView.swift
//  Sources
//
//  Created on November 26, 2025.
//

import SwiftUI

struct ArticleListView: View {
    @Bindable var viewModel: ArticleListViewModel
    let feed: Feed?
    
    @Bindable var feedListViewModel: FeedListViewModel
    
    private var hasContent: Bool {
        feed != nil || feedListViewModel.selectedSmartFolder != nil
    }
    
    private var navigationTitle: String {
        if let feed = feed {
            return feed.title
        } else if let smartFolder = feedListViewModel.selectedSmartFolder {
            switch smartFolder {
            case .allFeeds: return "All Feeds"
            case .unread: return "Unread"
            case .recent: return "Recent"
            }
        }
        return "Articles"
    }
    
    var body: some View {
        Group {
            if hasContent {
                articleListContent
            } else {
                ContentUnavailableView(
                    "No Feed Selected",
                    systemImage: "newspaper",
                    description: Text("Select a feed from the sidebar to view articles")
                )
            }
        }
    }
    
    @ViewBuilder
    private var articleListContent: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                    .padding(.leading, 8)
                TextField("Search articles", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(.background)
            
            Divider()
            
            List(selection: $viewModel.selectedArticle) {
                ForEach(viewModel.articles) { article in
                    ArticleRow(article: article)
                        .tag(article)
                        .contextMenu {
                            Button(article.isRead ? "Mark as Unread" : "Mark as Read") {
                                viewModel.toggleReadStatus(article)
                            }
                        }
                }
            }
        }
        .navigationTitle(navigationTitle)
        .toolbar {
            if feedListViewModel.selectedSmartFolder == .recent {
                ToolbarItem(placement: .automatic) {
                    Picker("Time Range", selection: $viewModel.recencyFilter) {
                        ForEach(ArticleListViewModel.RecencyFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                if viewModel.recencyFilter == .custom {
                    ToolbarItem(placement: .automatic) {
                        HStack(alignment: .center, spacing: 8) {
                            Text("From")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                                .fixedSize()
                                .padding(.leading, 8)
                            DatePicker("", selection: $viewModel.customStartDate, displayedComponents: [.date])
                                .datePickerStyle(.field)
                                .labelsHidden()
                                .fixedSize()
                        }
                        .frame(height: 28)
                    }
                    
                    ToolbarItem(placement: .automatic) {
                        HStack(alignment: .center, spacing: 8) {
                            Text("To")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                                .fixedSize()
                                .padding(.leading, 8)
                            DatePicker("", selection: $viewModel.customEndDate, displayedComponents: [.date])
                                .datePickerStyle(.field)
                                .labelsHidden()
                                .fixedSize()
                                .padding(.trailing, 8)
                        }
                        .frame(height: 28)
                    }
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Picker("Sort", selection: $viewModel.sortOrder) {
                                Text("Newest First").tag(ArticleListViewModel.SortOrder.dateDescending)
                                Text("Oldest First").tag(ArticleListViewModel.SortOrder.dateAscending)
                                Text("Title").tag(ArticleListViewModel.SortOrder.titleAscending)
                            }
                            
                            Divider()
                            
                            Toggle("Unread Only", isOn: $viewModel.showUnreadOnly)
                        } label: {
                            Label("Options", systemImage: "ellipsis.circle")
                        }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        if let feed = feed {
                            viewModel.markAllAsRead(for: feed)
                        }
                    }) {
                        Label("Mark All Read", systemImage: "checkmark.circle")
                    }
                    .disabled(viewModel.articles.isEmpty)
                }
            }
            .onChange(of: viewModel.sortOrder) {
                viewModel.loadArticles(for: feed)
            }
            .onChange(of: viewModel.showUnreadOnly) {
                viewModel.loadArticles(for: feed)
            }
            .onChange(of: viewModel.searchText) {
                if let feed = feed {
                    viewModel.loadArticles(for: feed)
                } else if let smartFolder = feedListViewModel.selectedSmartFolder {
                    switch smartFolder {
                    case .allFeeds:
                        viewModel.loadAllArticles()
                    case .unread:
                        viewModel.loadUnreadArticles()
                    case .recent:
                        viewModel.loadRecentArticles()
                    }
                }
            }
            .onChange(of: viewModel.recencyFilter) {
                if feedListViewModel.selectedSmartFolder == .recent {
                    viewModel.loadRecentArticles()
                }
            }
            .onChange(of: viewModel.customStartDate) {
                if viewModel.recencyFilter == .custom && feedListViewModel.selectedSmartFolder == .recent {
                    viewModel.loadRecentArticles()
                }
            }
            .onChange(of: viewModel.customEndDate) {
                if viewModel.recencyFilter == .custom && feedListViewModel.selectedSmartFolder == .recent {
                    viewModel.loadRecentArticles()
                }
            }
    }
}

struct ArticleRow: View {
    let article: Article
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(article.title)
                .font(.headline)
                .fontWeight(article.isRead ? .regular : .bold)
                .foregroundStyle(article.isRead ? .secondary : .primary)
            
            if let summary = article.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                if let author = article.author {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(article.publishedDate, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
