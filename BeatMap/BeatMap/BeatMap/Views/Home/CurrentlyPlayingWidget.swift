// MARK: - File Header
//
// CurrentlyPlayingWidget.swift
// BeatMap
//
// Version: 1.2.0 (Smart Refresh - No Animation on Same Track)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI

/// Widget displaying the user's last played Spotify track.
/// Persists even when nothing is currently playing, making it always available for journaling.
/// Smart refresh: Only animates when a genuinely new track is detected.
struct CurrentlyPlayingWidget: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var lastPlayedTrack: PlayHistoryObject?
    @State private var isLoading = true
    @State private var isRefreshing = false
    
    // Closure to handle opening new entry sheet
    let onJournalTap: (Song) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "music.note")
                    .foregroundColor(themeManager.currentTheme.accentColor)
                Text("Last Played")
                    .font(.headline)
                Spacer()
                
                // Refresh button with indicator
                Button(action: { Task { await fetchLastPlayed(isManualRefresh: true) } }) {
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                }
                .foregroundColor(themeManager.currentTheme.accentColor)
                .disabled(isRefreshing)
            }
            
            if isLoading {
                // Loading state (only on initial load)
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(themeManager.currentTheme.accentColor)
                    Spacer()
                }
                .padding(.vertical)
            } else if let historyItem = lastPlayedTrack {
                // Last played track
                HStack(spacing: 15) {
                    // Album art
                    AsyncImage(url: URL(string: historyItem.track.album.images.first?.url ?? "")) { image in
                        image.resizable()
                    } placeholder: {
                        ZStack {
                            themeManager.currentTheme.secondaryBackgroundColor
                            ProgressView()
                        }
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    
                    // Track info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(historyItem.track.name)
                            .font(.headline)
                            .lineLimit(1)
                        Text(historyItem.track.artists.first?.name ?? "Unknown Artist")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .lineLimit(1)
                        
                        // Time ago
                        if let playedDate = parseSpotifyDate(historyItem.played_at) {
                            Text(timeAgo(from: playedDate))
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    
                    Spacer()
                    
                    // Journal button
                    Button(action: {
                        let song = Song(
                            id: historyItem.track.id,
                            title: historyItem.track.name,
                            artist: historyItem.track.artists.first?.name ?? "Unknown",
                            albumArtURL: historyItem.track.album.images.first?.url
                        )
                        onJournalTap(song)
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Journal")
                                .font(.caption2)
                        }
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            } else {
                // No recent tracks
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "music.note.list")
                            .font(.title)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        Text("No recent tracks")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    Spacer()
                }
                .padding(.vertical)
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        .onAppear {
            Task { await fetchLastPlayed(isManualRefresh: false) }
        }
    }
    
    // MARK: - API Call
    
    @MainActor
    private func fetchLastPlayed(isManualRefresh: Bool) async {
        // Only show full loading state on initial load
        if lastPlayedTrack == nil && !isRefreshing {
            isLoading = true
        }
        
        // Show refresh indicator for manual refreshes
        if isManualRefresh {
            isRefreshing = true
        }
        
        guard let url = URL(string: "https://api.spotify.com/v1/me/player/recently-played?limit=1") else {
            isLoading = false
            isRefreshing = false
            return
        }
        
        let request = URLRequest(url: url)
        let response: RecentlyPlayedResponse? = await SpotifyAPIManager.shared.makeAPIRequest(request: request)
        
        // Only update if the track has actually changed
        if let newTrack = response?.items.first {
            // Compare track IDs to detect if it's actually a new song
            if lastPlayedTrack?.track.id != newTrack.track.id {
                print("🎵 New track detected: \(newTrack.track.name)")
                withAnimation {
                    lastPlayedTrack = newTrack
                }
            } else {
                // Same track, just update timestamp silently without animation
                lastPlayedTrack = newTrack
            }
        }
        
        isLoading = false
        isRefreshing = false
    }
    
    // MARK: - Helper Functions
    
    /// Parse Spotify's ISO 8601 date format
    private func parseSpotifyDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    /// Format time ago string (e.g., "5 minutes ago", "2 hours ago")
    private func timeAgo(from date: Date) -> String {
        let interval = Date.now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}
