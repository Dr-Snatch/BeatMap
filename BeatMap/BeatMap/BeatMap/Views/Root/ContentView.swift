// MARK: - File Header
//
// ContentView.swift
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

/// The root view of BeatMap that manages authentication flow.
/// Routes users to login, onboarding, or main app based on authentication state.
struct ContentView: View {

    // MARK: - Environment
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - Body
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea()

            // Route based on authentication state
            switch authManager.authState {
            case .checking:
                ProgressView("Checking Session...")
                    .tint(themeManager.currentTheme.accentColor)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)

            case .loggedOut:
                LoginView()

            case .loggingIn:
                ProgressView("Logging In...")
                    .tint(themeManager.currentTheme.accentColor)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)

            case .onboarding:
                RecentlyPlayedView()

            case .loggedIn:
                MainAppView()
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .alert("Error", isPresented: .constant(authManager.errorMessage != nil), actions: {
            Button("OK") {
                authManager.clearError()
            }
        }, message: {
            Text(authManager.errorMessage ?? "An unknown error occurred.")
        })
    }
}

#Preview {
    PreviewContainer {
        ContentView()
    }
}
