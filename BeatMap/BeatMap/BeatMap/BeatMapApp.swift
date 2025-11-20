// MARK: - File Header
//
// BeatMapApp.swift
// BeatMap
//
// Version: 1.1.0
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI
import OAuthSwift

@main
struct BeatMapApp: App {

    @StateObject private var journalStore = JournalStore()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var shazamManager = ShazamManager()
    
    init() {
        _ = CrashReporter.shared
        print("🛡️ Crash reporting initialized")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .ignoresSafeArea()
                .environmentObject(journalStore)
                .environmentObject(themeManager)
                .environmentObject(locationManager)
                .environmentObject(authManager)
                .environmentObject(shazamManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        print("📱 App received URL: \(url.absoluteString)")
        
        if url.scheme == "beatmap" {
            print("✅ Processing Spotify OAuth callback")
            OAuthSwift.handle(url: url)
        } else {
            print("⚠️ Unrecognized URL scheme: \(url.scheme ?? "unknown")")
        }
    }
}
