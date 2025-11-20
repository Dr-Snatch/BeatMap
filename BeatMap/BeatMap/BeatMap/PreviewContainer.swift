// MARK: - File Header
//
// PreviewContainer.swift
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
import Combine

/// Helper view providing a complete environment for SwiftUI Previews.
/// Creates and injects all necessary managers and services for BeatMap views to preview correctly.
struct PreviewContainer<Content: View>: View {
    
    // Create instances of all managers for preview environment
    @StateObject private var journalStore = JournalStore()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var shazamManager = ShazamManager()
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environmentObject(journalStore)
            .environmentObject(themeManager)
            .environmentObject(locationManager)
            .environmentObject(authManager)
            .environmentObject(shazamManager)
    }
}
