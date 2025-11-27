//
//  SidebarView.swift
//  Sources
//
//  Created on November 26, 2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SidebarView: View {
    @Bindable var viewModel: FeedListViewModel
    @State private var showingAddFeed = false
    @State private var showingAddFolder = false
    @State private var searchText = ""
    @State private var showingImportPicker = false
    @State private var showingExportPicker = false
    @State private var isSelecting = false
    @State private var showingMoveMenu = false
    
    var filteredFeeds: [Feed] {
        if searchText.isEmpty {
            return viewModel.feeds
        }
        return viewModel.feeds.filter { feed in
            feed.title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List(selection: isSelecting ? $viewModel.selectedFeeds : Binding(
            get: { viewModel.selectedFeed.map { Set([$0]) } ?? [] },
            set: { viewModel.selectedFeed = $0.first }
        )) {
            // Smart folders
            Section("Smart Folders") {
                Button(action: {
                    viewModel.selectedFeed = nil
                    viewModel.selectedSmartFolder = .allFeeds
                }) {
                    HStack {
                        Image(systemName: "tray.fill")
                        Text("All Feeds")
                        Spacer()
                        let totalUnread = viewModel.feeds.reduce(0, { $0 + $1.unreadCount })
                        if totalUnread > 0 {
                            Text("\(totalUnread)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    viewModel.selectedFeed = nil
                    viewModel.selectedSmartFolder = .unread
                }) {
                    HStack {
                        Image(systemName: "circle.fill")
                        Text("Unread")
                        Spacer()
                        let totalUnread = viewModel.feeds.reduce(0, { $0 + $1.unreadCount })
                        if totalUnread > 0 {
                            Text("\(totalUnread)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    viewModel.selectedFeed = nil
                    viewModel.selectedSmartFolder = .recent
                }) {
                    HStack {
                        Image(systemName: "clock.fill")
                        Text("Recent")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
            
            // Folders with feeds
            ForEach(viewModel.folders) { folder in
                Section {
                    ForEach(folder.feeds.filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }) { feed in
                        FeedRow(feed: feed)
                            .tag(feed)
                            .contextMenu {
                                feedContextMenu(for: feed)
                            }
                    }
                } header: {
                    HStack {
                        Text(folder.name)
                        Spacer()
                        if folder.unreadCount > 0 {
                            Text("\(folder.unreadCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contextMenu {
                        Button("Delete Folder", role: .destructive) {
                            viewModel.deleteFolder(folder)
                        }
                    }
                }
            }
            
            // Feeds without folders
            let unorganizedFeeds = filteredFeeds.filter { $0.folder == nil }
            if !unorganizedFeeds.isEmpty {
                Section("Feeds") {
                    ForEach(unorganizedFeeds) { feed in
                        FeedRow(feed: feed)
                            .tag(feed)
                            .contextMenu {
                                feedContextMenu(for: feed)
                            }
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search feeds")
        .navigationTitle("Sources")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                if isSelecting {
                    HStack(spacing: 12) {
                        Menu {
                            Button("None") {
                                viewModel.moveFeeds(viewModel.selectedFeeds, to: nil)
                                isSelecting = false
                            }
                            
                            Divider()
                            
                            ForEach(viewModel.folders) { folder in
                                Button(folder.name) {
                                    viewModel.moveFeeds(viewModel.selectedFeeds, to: folder)
                                    isSelecting = false
                                }
                            }
                        } label: {
                            Label("Move", systemImage: "folder")
                        }
                        .disabled(viewModel.selectedFeeds.isEmpty)
                        
                        Button(role: .destructive) {
                            viewModel.deleteFeeds(viewModel.selectedFeeds)
                            isSelecting = false
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(viewModel.selectedFeeds.isEmpty)
                    }
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Add Feed...") {
                        showingAddFeed = true
                    }
                    
                    Button("Add Folder...") {
                        showingAddFolder = true
                    }
                    
                    Divider()
                    
                    Button("Select Feeds...") {
                        withAnimation {
                            isSelecting = true
                        }
                    }
                    
                    Divider()
                    
                    Button("Import OPML...") {
                        showingImportPicker = true
                    }
                    
                    Button("Export OPML...") {
                        showingExportPicker = true
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                if !isSelecting {
                    Button(action: {
                        Task {
                            await viewModel.refreshAllFeeds()
                        }
                    }) {
                        Label("Refresh All", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isRefreshing)
                } else {
                    Button("Done") {
                        withAnimation {
                            isSelecting = false
                            viewModel.selectedFeeds.removeAll()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddFeed) {
            AddFeedSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddFolder) {
            AddFolderSheet(viewModel: viewModel)
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.xml, .opml],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                viewModel.importOPML(from: url)
            }
        }
        .fileExporter(
            isPresented: $showingExportPicker,
            document: OPMLDocument(content: viewModel.exportOPML()),
            contentType: .opml,
            defaultFilename: "Sources-Feeds.opml"
        ) { result in
            if case .failure(let error) = result {
                viewModel.errorMessage = "Failed to export: \(error.localizedDescription)"
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .addFeedRequested)) { _ in
            showingAddFeed = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .addFolderRequested)) { _ in
            showingAddFolder = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllRequested)) { _ in
            Task {
                await viewModel.refreshAllFeeds()
            }
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
    
    @ViewBuilder
    private func feedContextMenu(for feed: Feed) -> some View {
        // If we're in selection mode and this feed is selected, operate on all selected feeds
        let feedsToOperate = isSelecting && viewModel.selectedFeeds.contains(feed) 
            ? viewModel.selectedFeeds 
            : Set([feed])
        let isMultiple = feedsToOperate.count > 1
        
        if !isMultiple {
            Button("Refresh") {
                Task {
                    await viewModel.refreshFeed(feed)
                }
            }
        }
        
        Menu("Move to Folder") {
            Button("None") {
                if isMultiple {
                    viewModel.moveFeeds(feedsToOperate, to: nil)
                    isSelecting = false
                } else {
                    viewModel.moveFeed(feed, to: nil)
                }
            }
            
            Divider()
            
            ForEach(viewModel.folders) { folder in
                Button(folder.name) {
                    if isMultiple {
                        viewModel.moveFeeds(feedsToOperate, to: folder)
                        isSelecting = false
                    } else {
                        viewModel.moveFeed(feed, to: folder)
                    }
                }
            }
        }
        
        Divider()
        
        Button("Delete\(isMultiple ? " (\(feedsToOperate.count))" : "")", role: .destructive) {
            if isMultiple {
                viewModel.deleteFeeds(feedsToOperate)
                isSelecting = false
            } else {
                viewModel.deleteFeed(feed)
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

struct AddFolderSheet: View {
    @Bindable var viewModel: FeedListViewModel
    @State private var folderName = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Folder Name", text: $folderName)
                        .textFieldStyle(.plain)
                } footer: {
                    Text("Create a folder to organize your feeds.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Folder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addFolder(name: folderName)
                        dismiss()
                    }
                    .disabled(folderName.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 200)
    }
}
