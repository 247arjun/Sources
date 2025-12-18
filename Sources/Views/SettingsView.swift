//
//  SettingsView.swift
//  Sources
//
//  Created on November 26, 2025.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    var viewModel: FeedListViewModel?
    
    @State private var cacheSize: Int64 = 0
    @State private var cachedArticleCount: Int = 0
    @State private var lastCleanup: Date = Date()
    @State private var showingClearConfirmation = false
    @State private var showingCleanupConfirmation = false
    @State private var isPerformingCleanup = false
    @State private var cleanupResult: CleanupResult?
    
    var body: some View {
        Form {
            Section {
                Toggle("Automatically refresh feeds", isOn: $settings.autoRefreshEnabled)
                
                HStack {
                    Text("Refresh interval:")
                    Stepper(
                        "\(settings.refreshIntervalMinutes) minutes",
                        value: $settings.refreshIntervalMinutes,
                        in: 5...1440,
                        step: 5
                    )
                }
                .disabled(!settings.autoRefreshEnabled)
            } header: {
                Text("Automatic Refresh")
            } footer: {
                Text("Sources will automatically check for new articles at the specified interval.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Picker("Cache size limit:", selection: $settings.cacheSizeLimit) {
                    ForEach(AppSettings.CacheSizeLimit.allCases, id: \.self) { limit in
                        Text(limit.displayName).tag(limit)
                    }
                }
                
                Picker("Auto-clean cache older than:", selection: $settings.cacheAge) {
                    ForEach(AppSettings.CacheAge.allCases, id: \.self) { age in
                        Text(age.displayName).tag(age)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Current cache size:")
                        Spacer()
                        Text(formatSize(cacheSize))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Cached articles:")
                        Spacer()
                        Text("\(cachedArticleCount)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Last cleaned:")
                        Spacer()
                        Text(lastCleanup, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
                
                Button("Clear Cache Now") {
                    showingClearConfirmation = true
                }
                .confirmationDialog(
                    "Clear all cached article content?",
                    isPresented: $showingClearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Clear Cache", role: .destructive) {
                        Task {
                            try? await CacheManager.shared.clearCache()
                            await loadCacheStats()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } header: {
                Text("Cache Management")
            } footer: {
                Text("Article content and images are cached locally for faster loading and offline access.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Picker("Excerpt length:", selection: $settings.excerptLength) {
                    ForEach(AppSettings.ExcerptLength.allCases, id: \.self) { length in
                        Text(length.displayName).tag(length)
                    }
                }
            } header: {
                Text("Article List Appearance")
            } footer: {
                Text("Control how many lines of article preview text are shown in the article list.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Remove duplicate feeds and folders, and clean up feeds that are no longer accessible.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let result = cleanupResult {
                        HStack {
                            Image(systemName: result.totalItemsRemoved > 0 ? "checkmark.circle.fill" : "info.circle.fill")
                                .foregroundStyle(result.totalItemsRemoved > 0 ? .green : .blue)
                            Text(result.summary)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(action: {
                        showingCleanupConfirmation = true
                    }) {
                        HStack {
                            if isPerformingCleanup {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 4)
                            }
                            Text(isPerformingCleanup ? "Cleaning Up..." : "Run Cleanup")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isPerformingCleanup || viewModel == nil)
                    .confirmationDialog(
                        "Run cleanup operation?",
                        isPresented: $showingCleanupConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Run Cleanup") {
                            performCleanup()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will:\n• Remove duplicate feeds and folders\n• Test all feeds (3 retries each)\n• Remove feeds that fail to load\n\nThis may take a few minutes.")
                    }
                }
            } header: {
                Text("Feed Cleanup")
            } footer: {
                Text("Tests each feed with 3 retry attempts before removing. Duplicate feeds and folders will be merged.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 650)
        .task {
            await loadCacheStats()
        }
    }
    
    private func loadCacheStats() async {
        let stats = await CacheManager.shared.getCacheStats()
        cacheSize = stats.size
        cachedArticleCount = stats.count
        lastCleanup = stats.lastCleanup
    }
    
    private func performCleanup() {
        guard let viewModel = viewModel else { return }
        
        isPerformingCleanup = true
        cleanupResult = nil
        
        Task {
            let result = await viewModel.performCleanup()
            
            await MainActor.run {
                cleanupResult = result
                isPerformingCleanup = false
            }
        }
    }
    
    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
