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
    var settings: AppSettings
    @State private var searchTask: Task<Void, Never>?
    @State private var groupedArticles: [Date: [Article]] = [:]
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var hasContent: Bool {
        feed != nil || feedListViewModel.selectedSmartFolder != nil || feedListViewModel.selectedFolder != nil
    }
    
    private func sectionTitle(for date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let articleDate = calendar.startOfDay(for: date)
        
        if articleDate == today {
            return "Today"
        } else if articleDate == calendar.date(byAdding: .day, value: -1, to: today) {
            return "Yesterday"
        } else {
            return Self.dateFormatter.string(from: date)
        }
    }
    
    private func updateGroupedArticles() {
        groupedArticles = Dictionary(grouping: viewModel.articles) { article in
            Calendar.current.startOfDay(for: article.publishedDate)
        }
    }
    
    private var navigationTitle: String {
        if let feed = feed {
            return feed.title
        } else if let folder = feedListViewModel.selectedFolder {
            return folder.name
        } else if let smartFolder = feedListViewModel.selectedSmartFolder {
            switch smartFolder {
            case .allFeeds: return "All Feeds"
            case .unread: return "Unread"
            case .starred: return "Starred"
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
                ForEach(groupedArticles.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(sectionTitle(for: date))) {
                        ForEach(groupedArticles[date] ?? []) { article in
                            ArticleRow(article: article, excerptLines: settings.excerptLength.rawValue)
                                .tag(article)
                                .contextMenu {
                                    Button(article.isRead ? "Mark as Unread" : "Mark as Read") {
                                        viewModel.toggleReadStatus(article)
                                    }
                                }
                        }
                    }
                }
            }
        }
        .navigationTitle(navigationTitle)
        .safeAreaInset(edge: .top) {
            VStack(spacing: 8) {
                // Recency filter tabs (only for Recent smart folder)
                if feedListViewModel.selectedSmartFolder == .recent {
                    Picker("Time Range", selection: $viewModel.recencyFilter) {
                        ForEach(ArticleListViewModel.RecencyFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    
                    if viewModel.recencyFilter == .custom {
                        HStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Text("From")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                                DatePicker("", selection: $viewModel.customStartDate, displayedComponents: [.date])
                                    .datePickerStyle(.field)
                                    .labelsHidden()
                            }
                            
                            HStack(spacing: 8) {
                                Text("To")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                                DatePicker("", selection: $viewModel.customEndDate, displayedComponents: [.date])
                                    .datePickerStyle(.field)
                                    .labelsHidden()
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 4)
                    }
                }
                
                // Filter and sort toolbar
                HStack(spacing: 12) {
                    // Sort picker
                    Menu {
                        Picker("Sort", selection: $viewModel.sortOrder) {
                            Label("Newest First", systemImage: "arrow.down").tag(ArticleListViewModel.SortOrder.dateDescending)
                            Label("Oldest First", systemImage: "arrow.up").tag(ArticleListViewModel.SortOrder.dateAscending)
                            Label("Title", systemImage: "textformat").tag(ArticleListViewModel.SortOrder.titleAscending)
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Label("Sort", systemImage: "line.3.horizontal.decrease")
                            .labelStyle(.iconOnly)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    
                    // Unread toggle
                    Toggle(isOn: $viewModel.showUnreadOnly) {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            .labelStyle(.iconOnly)
                    }
                    .toggleStyle(.button)
                    .tint(viewModel.showUnreadOnly ? .blue : .gray)
                    
                    Spacer()
                    
                    // Mark all as read
                    Button(action: {
                        if let feed = feed {
                            viewModel.markAllAsRead(for: feed)
                        }
                    }) {
                        Label("Mark All Read", systemImage: "checkmark.circle")
                            .labelStyle(.iconOnly)
                    }
                    .disabled(viewModel.articles.isEmpty)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .background(.background)
        }
            .onChange(of: viewModel.sortOrder) {
                reloadArticles()
            }
            .onChange(of: viewModel.showUnreadOnly) {
                reloadArticles()
            }
            .onChange(of: viewModel.searchText) {
                // Debounce search to avoid excessive queries while typing
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    
                    if let feed = feed {
                        viewModel.loadArticles(for: feed)
                    } else if let smartFolder = feedListViewModel.selectedSmartFolder {
                        switch smartFolder {
                        case .allFeeds:
                            viewModel.loadAllArticles()
                        case .unread:
                            viewModel.loadUnreadArticles()
                        case .starred:
                            viewModel.loadStarredArticles()
                        case .recent:
                            viewModel.loadRecentArticles()
                        }
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
            .onReceive(NotificationCenter.default.publisher(for: .focusSearchRequested)) { _ in
                // In a full implementation, this would focus the search field
                // SwiftUI doesn't have a direct way to focus TextField on macOS
            }
            .onChange(of: viewModel.articles) { _, _ in
                updateGroupedArticles()
            }
            .onAppear {
                updateGroupedArticles()
            }
    }
}

// Extension to allow notification handling from ArticleListView
extension ArticleListView {
    func handleSelectAllArticles() {
        // This would be handled through the ArticleListViewModel
        // For now, we'll leave this as a placeholder for future multi-select in article list
    }
    
    func reloadArticles() {
        if let feed = feed {
            viewModel.loadArticles(for: feed)
        } else if let folder = feedListViewModel.selectedFolder {
            viewModel.loadArticles(for: folder)
        } else if let smartFolder = feedListViewModel.selectedSmartFolder {
            switch smartFolder {
            case .allFeeds:
                viewModel.loadAllArticles()
            case .unread:
                viewModel.loadUnreadArticles()
            case .starred:
                viewModel.loadStarredArticles()
            case .recent:
                viewModel.loadRecentArticles()
            }
        }
    }
}

struct ArticleRow: View {
    let article: Article
    var excerptLines: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(article.title)
                .font(.headline)
                .fontWeight(article.isRead ? .regular : .bold)
                .foregroundStyle(article.isRead ? .secondary : .primary)
            
            if excerptLines > 0, let summary = article.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(excerptLines)
            }
            
            HStack {
                if let feedTitle = article.feed?.title {
                    Text(feedTitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                if article.isStarred {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
                
                Text(article.publishedDate, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}


