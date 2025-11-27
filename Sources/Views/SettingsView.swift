//
//  SettingsView.swift
//  Sources
//
//  Created on November 26, 2025.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    
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
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 200)
    }
}
