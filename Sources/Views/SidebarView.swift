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
    
    private var totalUnreadCount: Int {
        viewModel.feeds.reduce(0, { $0 + $1.unreadCount })
    }
    
    private var smartFoldersSection: some View {
        Section("Smart Folders") {
            SmartFolderRow(
                icon: "tray.fill",
                title: "All Feeds",
                count: totalUnreadCount > 0 ? totalUnreadCount : nil,
                isSelected: viewModel.selectedSmartFolder == .allFeeds,
                action: {
                    viewModel.selectedFeed = nil
                    viewModel.selectedSmartFolder = .allFeeds
                },
                markAllAsReadAction: {
                    viewModel.markAllAsReadInAllFeeds()
                }
            )
            
            SmartFolderRow(
                icon: "circle.fill",
                title: "Unread",
                count: totalUnreadCount > 0 ? totalUnreadCount : nil,
                isSelected: viewModel.selectedSmartFolder == .unread,
                action: {
                    viewModel.selectedFeed = nil
                    viewModel.selectedSmartFolder = .unread
                },
                markAllAsReadAction: {
                    viewModel.markAllAsReadInAllFeeds()
                }
            )
            
            SmartFolderRow(
                icon: "star.fill",
                title: "Starred",
                count: nil,
                isSelected: viewModel.selectedSmartFolder == .starred,
                action: {
                    viewModel.selectedFeed = nil
                    viewModel.selectedSmartFolder = .starred
                },
                markAllAsReadAction: {
                    viewModel.markAllAsReadInStarred()
                }
            )
            
            SmartFolderRow(
                icon: "clock.fill",
                title: "Recent",
                count: nil,
                isSelected: viewModel.selectedSmartFolder == .recent,
                action: {
                    viewModel.selectedFeed = nil
                    viewModel.selectedSmartFolder = .recent
                },
                markAllAsReadAction: {
                    viewModel.markAllAsReadInRecent()
                }
            )
        }
    }
    
    var body: some View {
        List(selection: isSelecting ? $viewModel.selectedFeeds : Binding(
            get: { viewModel.selectedFeed.map { Set([$0]) } ?? [] },
            set: { viewModel.selectedFeed = $0.first }
        )) {
            smartFoldersSection
            
            // Folders with feeds
            ForEach(viewModel.folders) { folder in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { !viewModel.isFolderCollapsed(folder) },
                        set: { expanded in
                            withAnimation(.none) {
                                viewModel.toggleFolderCollapse(folder)
                            }
                        }
                    )
                ) {
                    ForEach(folder.feeds.filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }) { feed in
                        FeedRow(feed: feed)
                            .tag(feed)
                            .contextMenu {
                                feedContextMenu(for: feed)
                            }
                            .transition(.identity)
                    }
                } label: {
                    Button(action: {
                        viewModel.selectedFeed = nil
                        viewModel.selectedSmartFolder = nil
                        viewModel.selectedFolder = folder
                    }) {
                        HStack {
                            Text(folder.name)
                                .foregroundStyle(viewModel.selectedFolder == folder ? Color.accentColor : .primary)
                            Spacer()
                            if folder.unreadCount > 0 {
                                Text("\(folder.unreadCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .listRowBackground(viewModel.selectedFolder == folder ? Color.accentColor.opacity(0.15) : Color.clear)
                    .contextMenu {
                        Button("Mark All as Read") {
                            viewModel.markAllAsRead(in: folder)
                        }
                        
                        Divider()
                        
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
                    Menu {
                        if viewModel.hasRefreshError {
                            Section("Failed Feeds") {
                                ForEach(viewModel.failedFeeds, id: \.feed.id) { failedFeed in
                                    VStack(alignment: .leading) {
                                        Text(failedFeed.feed.title)
                                            .font(.headline)
                                        Text(errorSummary(for: failedFeed.error))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            Button("Retry All") {
                                Task.detached {
                                    await viewModel.refreshAllFeeds()
                                }
                            }
                        } else {
                            Button("Refresh All Feeds") {
                                Task.detached {
                                    await viewModel.refreshAllFeeds()
                                }
                            }
                        }
                    } label: {
                        if viewModel.hasRefreshError {
                            Label("Refresh Errors", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        } else {
                            Label("Refresh All", systemImage: viewModel.isRefreshing ? "arrow.clockwise.circle.fill" : "arrow.clockwise")
                        }
                    }
                    .symbolEffect(.rotate, isActive: viewModel.isRefreshing && !viewModel.hasRefreshError)
                    .help(viewModel.hasRefreshError ? "Click to see which feeds failed" : "Refresh all feeds")
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
                // Track export error
                let dummyFeed = Feed(title: "OPML Export", feedURL: URL(string: "file://export")!, lastUpdated: Date())
                viewModel.failedFeeds = [(feed: dummyFeed, error: error)]
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    viewModel.hasRefreshError = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .addFeedRequested)) { _ in
            showingAddFeed = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .addFolderRequested)) { _ in
            showingAddFolder = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllRequested)) { _ in
            Task.detached {
                await viewModel.refreshAllFeeds()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .importOPMLRequested)) { _ in
            showingImportPicker = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportOPMLRequested)) { _ in
            showingExportPicker = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .editFeedRequested)) { _ in
            // Edit feed functionality - to be implemented
            if let feed = viewModel.selectedFeed {
                // This would open an edit sheet in a full implementation
                print("Edit feed: \(feed.title)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deleteFeedRequested)) { _ in
            if let feed = viewModel.selectedFeed {
                viewModel.deleteFeed(feed)
            }
        }
    }
    
    private func errorSummary(for error: Error) -> String {
        if let fetchError = error as? FetchError {
            switch fetchError {
            case .invalidURL:
                return "Invalid feed URL"
            case .networkError:
                return "Network connection failed"
            case .httpError(let statusCode):
                return "Server error (\(statusCode))"
            case .noData:
                return "No data received"
            }
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "No internet connection"
            case .timedOut:
                return "Request timed out"
            case .cannotFindHost, .dnsLookupFailed:
                return "Cannot find server"
            case .secureConnectionFailed:
                return "SSL/TLS error"
            default:
                return "Network error"
            }
        } else {
            return "Unknown error"
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
                Task.detached {
                    let result = await viewModel.refreshFeed(feed)
                    if case .failure(let error) = result {
                        await MainActor.run {
                            viewModel.failedFeeds = [(feed: feed, error: error)]
                            viewModel.hasRefreshError = true
                        }
                    }
                }
            }
            
            Button("Mark All as Read") {
                viewModel.markAllAsRead(for: feed)
            }
            
            Divider()
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
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "newspaper")
                            .foregroundStyle(.secondary)
                    case .empty:
                        ProgressView()
                            .scaleEffect(0.5)
                    @unknown default:
                        Image(systemName: "newspaper")
                            .foregroundStyle(.secondary)
                    }
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
    @State private var errorMessage: String?
    @State private var isAdding = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Feed URL", text: $urlString)
                        .textFieldStyle(.plain)
                        .disabled(isAdding)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
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
                    .disabled(isAdding)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isAdding ? "Adding..." : "Add") {
                        Task {
                            isAdding = true
                            errorMessage = nil
                            let result = await viewModel.addFeed(urlString: urlString)
                            isAdding = false
                            
                            switch result {
                            case .success:
                                await MainActor.run {
                                    dismiss()
                                }
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .disabled(urlString.isEmpty || isAdding)
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

struct SmartFolderRow: View {
    let icon: String
    let title: String
    let count: Int?
    let isSelected: Bool
    let action: () -> Void
    let markAllAsReadAction: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .contextMenu {
            Button("Mark All as Read") {
                markAllAsReadAction()
            }
        }
    }
}
