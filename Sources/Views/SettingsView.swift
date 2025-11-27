//
//  SettingsView.swift
//  Sources
//
//  Created on November 26, 2025.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @State private var cacheSize: Int64 = 0
    @State private var cachedArticleCount: Int = 0
    @State private var lastCleanup: Date = Date()
    @State private var showingClearConfirmation = false
    
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
                        Text(CacheManager.shared.formatSize(cacheSize))
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
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 500)
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
}
