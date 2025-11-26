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
    
    var body: some View {
        Group {
            if let feed = feed {
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
                .navigationTitle(feed.title)
                .toolbar {
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
                            viewModel.markAllAsRead(for: feed)
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
            } else {
                ContentUnavailableView(
                    "No Feed Selected",
                    systemImage: "newspaper",
                    description: Text("Select a feed from the sidebar to view articles")
                )
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
