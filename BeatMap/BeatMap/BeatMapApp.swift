// MARK: - File Header
//
// BeatMapApp.swift
// BeatMap
//
// Version: 1.0.0
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI

@main
struct BeatMapApp: App {
    // Startup state
    @State private var showSplash = true
    @State private var hasCompletedDeferredStartup = false
    
    // Use the correct pattern for each manager
    // AuthManager uses .shared (singleton)
    private let authManager = AuthManager.shared
    
    // These need to be @StateObject because they don't have .shared
    @StateObject private var journalStore = JournalStore()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var shazamManager = ShazamManager()
    
    init() {
        // Initialize crash reporting if you have it
        // CrashReportingManager.shared.initialize()
        print("🛡️ App initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                } else {
                    ContentView()
                        .environmentObject(journalStore)
                        .environmentObject(authManager)
                        .environmentObject(locationManager)
                        .environmentObject(themeManager)
                        .environmentObject(shazamManager)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSplash)
            .task {
                await performStartup()
            }
        }
    }
    
    // MARK: - Startup Sequence
    
    private func performStartup() async {
        // Phase 1: Critical initialization (happens immediately)
        print("🚀 Starting app initialization...")
        
        // Give the UI a moment to render
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Hide splash and show main UI
        showSplash = false
        
        // Phase 2: Deferred initialization (happens after UI is visible)
        await performDeferredStartup()
    }
    
    private func performDeferredStartup() async {
        guard !hasCompletedDeferredStartup else { return }
        
        print("⏳ Starting deferred initialization...")
        
        // Wait another moment to let the UI settle
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Check if user is authenticated
        // You'll need to check what property AuthManager uses
        // Common options: isAuthenticated, hasAccessToken, accessToken != nil
        // For now, I'll comment this out:
        
        // if authManager.hasAccessToken {
        //     print("🎵 Fetching recently played tracks...")
        //     // Move your recently played fetch here
        // }
        
        // Request location authorization (but don't start monitoring yet)
        locationManager.requestAuthorization()
        
        hasCompletedDeferredStartup = true
        print("✅ Deferred initialization complete")
    }
}
