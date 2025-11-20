// MARK: - File Header
//
// MainAppView.swift
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

/// The main container for BeatMap's primary interface after authentication.
/// Provides tab-based navigation between the app's core features.
struct MainAppView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Body
    
    var body: some View {
        TabView {
            // Home tab - Dashboard with quick actions
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            // Map tab - Geographic visualization of entries
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
            
            // Journal tab - Browse and search all entries
            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
            
            // Insights tab - Analytics and patterns
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.xaxis")
                }
            
            // Settings tab - App preferences and account
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .accentColor(themeManager.currentTheme.accentColor)
    }
}

#Preview {
    PreviewContainer {
        MainAppView()
    }
}
