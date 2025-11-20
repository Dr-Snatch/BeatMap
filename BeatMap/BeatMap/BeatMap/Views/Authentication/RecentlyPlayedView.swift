// MARK: - File Header
//
// RecentlyPlayedView.swift
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

/// Onboarding screen displaying the user's recently played Spotify tracks.
/// Confirms successful authentication by showing personalized data from the user's account.
struct RecentlyPlayedView: View {

    // MARK: - Environment
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - Body
    
    var body: some View {
        VStack {
            // Header
            Text("Recently Played")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)

            Text("Here are your recently played tracks from Spotify.")
                .font(.subheadline)
                .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.bottom)

            // Content
            if authManager.recentlyPlayedHistory.isEmpty {
                // Loading state
                Spacer()
                ProgressView("Loading tracks...")
                    .tint(themeManager.currentTheme.accentColor)
                Spacer()
            } else {
                // Track list
                List(authManager.recentlyPlayedHistory) { historyItem in
                    HStack(spacing: 15) {
                        // Album artwork
                        AsyncImage(url: URL(string: historyItem.track.album.images.first?.url ?? "")) { image in
                            image.resizable()
                        } placeholder: {
                            Image(systemName: "music.note")
                                .resizable()
                                .scaledToFit()
                                .padding(8)
                                .frame(width: 40, height: 40)
                                .background(themeManager.currentTheme.secondaryBackgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .frame(width: 40, height: 40)
                        .cornerRadius(4)

                        // Track info
                        VStack(alignment: .leading) {
                            Text(historyItem.track.name)
                                .fontWeight(.bold)
                            Text(historyItem.track.artists.first?.name ?? "Unknown Artist")
                                .font(.caption)
                        }
                        .foregroundStyle(themeManager.currentTheme.primaryTextColor)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            // Continue button
            Button(action: authManager.completeOnboarding) {
                Text("Continue to BeatMap")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.currentTheme.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding([.horizontal, .bottom])
        }
        .background(themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea())
    }
}

#Preview {
    PreviewContainer {
        RecentlyPlayedView()
    }
}
