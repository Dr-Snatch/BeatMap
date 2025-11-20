// MARK: - File Header
//
// LoginView.swift
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

/// The landing page and authentication screen for BeatMap.
/// Users log in with their Spotify account to access the app.
struct LoginView: View {

    // MARK: - Environment
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // App icon
            Image(systemName: "music.note.list")
                .font(.system(size: 100))
                .foregroundColor(themeManager.currentTheme.accentColor)
                .padding(.bottom, 20)

            // App name
            Text("BeatMap")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Tagline
            Text("Map your music. Journal your journey.")
                .font(.subheadline)
                .foregroundStyle(themeManager.currentTheme.secondaryTextColor)

            // Spotify login button
            Button(action: authManager.loginWithSpotify) {
                Text("Login with Spotify")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.currentTheme.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 30)
        }
        .foregroundColor(themeManager.currentTheme.primaryTextColor)
        .padding(40)
        .alert("Login Error", isPresented: .constant(authManager.errorMessage != nil), actions: {
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
        LoginView()
    }
}
