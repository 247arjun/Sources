//
//  SidebarView.swift
//  Sources
//
//  Created on November 26, 2025.
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Bindable var viewModel: FeedListViewModel
    @State private var showingAddFeed = false
    
    var body: some View {
        List(selection: $viewModel.selectedFeed) {
            ForEach(viewModel.feeds) { feed in
                FeedRow(feed: feed)
                    .tag(feed)
                    .contextMenu {
                        Button("Refresh") {
                            Task {
                                await viewModel.refreshFeed(feed)
                            }
                        }
                        
                        Divider()
                        
                        Button("Delete", role: .destructive) {
                            viewModel.deleteFeed(feed)
                        }
                    }
            }
        }
        .navigationTitle("Sources")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddFeed = true }) {
                    Label("Add Feed", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    Task {
                        await viewModel.refreshAllFeeds()
                    }
                }) {
                    Label("Refresh All", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isRefreshing)
            }
        }
        .sheet(isPresented: $showingAddFeed) {
            AddFeedSheet(viewModel: viewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .addFeedRequested)) { _ in
            showingAddFeed = true
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

struct FeedRow: View {
    let feed: Feed
    
    var body: some View {
        HStack {
            if let imageURL = feed.imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "newspaper")
                        .foregroundStyle(.secondary)
                }
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "newspaper")
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
            }
            
            Text(feed.title)
            
            Spacer()
            
            if feed.unreadCount > 0 {
                Text("\(feed.unreadCount)")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue, in: Capsule())
            }
        }
    }
}

struct AddFeedSheet: View {
    @Bindable var viewModel: FeedListViewModel
    @State private var urlString = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Feed URL", text: $urlString)
                        .textFieldStyle(.plain)
                } footer: {
                    Text("Enter the URL of an RSS or Atom feed, or a website URL to auto-discover feeds.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Feed")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addFeed(urlString: urlString)
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(urlString.isEmpty || viewModel.isRefreshing)
                }
            }
        }
        .frame(width: 400, height: 200)
    }
}
