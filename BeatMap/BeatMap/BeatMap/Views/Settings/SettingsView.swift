// MARK: - File Header
//
// SettingsView.swift
// BeatMap
//
// Version: 1.1.0 (Enhanced Settings)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI

/// Comprehensive settings and preferences screen for BeatMap.
struct SettingsView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var journalStore: JournalStore
    
    @State private var showingClearDataAlert = false
    @State private var showingAboutSheet = false
    @State private var showingDebugLogs = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea()
                
                Form {
                    // Account Section
                    Section(header: Text("Account")) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(themeManager.currentTheme.accentColor)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Spotify Account")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                        
                        Button(role: .destructive, action: {
                            authManager.logout()
                        }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(.red)
                        }
                    }
                    .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                    
                    // Appearance
                    Section(header: Text("Appearance")) {
                        Picker("Theme", selection: Binding(
                            get: { themeManager.currentTheme },
                            set: { themeManager.setTheme($0) }
                        )) {
                            ForEach(Theme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                    }
                    .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                    
                    // Data Management
                    Section(header: Text("Data Management")) {
                        HStack {
                            Label("Journal Entries", systemImage: "book.fill")
                            Spacer()
                            Text("\(journalStore.entries.count)")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        
                        HStack {
                            Label("Storage", systemImage: "internaldrive")
                            Spacer()
                            Text("Core Data")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                .font(.caption)
                        }
                        
                        Button(role: .destructive, action: {
                            showingClearDataAlert = true
                        }) {
                            Label("Clear All Entries", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                    .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                    
                    // About
                    Section(header: Text("About")) {
                        HStack {
                            Label("Version", systemImage: "info.circle")
                            Spacer()
                            Text("1.1.0")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        
                        Button(action: { showingAboutSheet = true }) {
                            Label("About BeatMap", systemImage: "info.circle.fill")
                        }
                        
                        Link(destination: URL(string: "mailto:beatmaphelp@gmail.com")!) {
                            Label("Contact Support", systemImage: "envelope")
                        }
                    }
                    .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                    
                    // Debug
                    Section(header: Text("Debug & Support")) {
                        Button(action: { showingDebugLogs = true }) {
                            Label("Send Debug Logs", systemImage: "ladybug")
                        }
                    }
                    .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                }
                .navigationTitle("Settings")
                .scrollContentBackground(.hidden)
            }
        }
        .alert("Clear All Entries?", isPresented: $showingClearDataAlert, actions: {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                clearAllEntries()
            }
        }, message: {
            Text("This will permanently delete all \(journalStore.entries.count) journal entries from Core Data. This action cannot be undone.")
        })
        .sheet(isPresented: $showingAboutSheet) {
            AboutView()
        }
        .sheet(isPresented: $showingDebugLogs) {
            DebugLogsView()
        }
    }
    
    private func clearAllEntries() {
        journalStore.deleteAll()
        LogManager.shared.log("All entries cleared by user from Core Data", level: .warning)
    }
}

// MARK: - About View

struct AboutView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea()
                
                VStack(spacing: 25) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 80))
                        .foregroundColor(themeManager.currentTheme.accentColor)
                        .padding(.top, 40)
                    
                    Text("BeatMap")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version 1.1.0")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    Text("Map your music. Journal your journey.")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Text("Created by A. Wheildon")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .padding(.bottom, 40)
                }
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Debug Logs View

struct DebugLogsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    private let supportEmail = "beatmaphelp@gmail.com"
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "ladybug.fill")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.currentTheme.accentColor)
                        .padding(.top, 30)
                    
                    Text("Debug Logs")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(LogManager.shared.logs.count) log entries")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    VStack(spacing: 12) {
                        Button(action: sendDebugEmail) {
                            Label("Email Debug Report", systemImage: "envelope.fill")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeManager.currentTheme.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: copyLogsToClipboard) {
                            Label("Copy to Clipboard", systemImage: "doc.on.doc")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeManager.currentTheme.secondaryBackgroundColor)
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Logs:")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(LogManager.shared.logs.suffix(20).reversed())) { entry in
                                    Text("\(entry.level.rawValue) \(entry.message)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                        .padding(8)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            }
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func sendDebugEmail() {
        let report = LogManager.shared.generateLogReport()
        let subject = "BeatMap Debug Report - \(Date.now.formatted(date: .abbreviated, time: .omitted))"
        
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = report.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let mailtoString = "mailto:\(supportEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)"
        
        if let mailtoURL = URL(string: mailtoString) {
            UIApplication.shared.open(mailtoURL)
            LogManager.shared.log("Debug email opened", level: .info)
        }
    }
    
    private func copyLogsToClipboard() {
        let report = LogManager.shared.generateLogReport()
        UIPasteboard.general.string = report
        LogManager.shared.log("Logs copied to clipboard", level: .info)
    }
}

#Preview {
    PreviewContainer {
        SettingsView()
    }
}
