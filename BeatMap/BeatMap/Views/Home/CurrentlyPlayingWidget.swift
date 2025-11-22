// MARK: - File Header
//
// CurrentlyPlayingWidget.swift
// BeatMap
//
// Version: 2.3.0 (Smooth UI Updates)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI

/// Widget displaying the user's currently playing Spotify track with live progress.
/// Auto-refreshes every 5 seconds and shows real-time playback progress.
struct CurrentlyPlayingWidget: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var currentlyPlaying: CurrentlyPlayingResponse?
    @State private var isInitialLoad = true
    @State private var lastFetchTime: Date?
    
    // Track previous state to detect changes
    @State private var previousTrackId: String?
    @State private var previousIsPlaying: Bool?
    
    // Progress tracking
    @State private var currentProgress: Double = 0.0 // 0.0 to 1.0
    @State private var displayedProgressMs: Int = 0
    @State private var progressTask: Task<Void, Never>?
    @State private var refreshTask: Task<Void, Never>?
    
    // Closure to handle opening new entry sheet
    let onJournalTap: (Song) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: currentlyPlaying?.is_playing == true ? "play.circle.fill" : "pause.circle.fill")
                    .foregroundColor(themeManager.currentTheme.accentColor)
                Text(currentlyPlaying?.is_playing == true ? "Now Playing" : "Paused")
                    .font(.headline)
                Spacer()
                
                // Refresh button
                Button(action: {
                    Task {
                        isInitialLoad = true
                        await fetchCurrentlyPlaying()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
            
            if isInitialLoad {
                // Loading state (only on initial load)
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(themeManager.currentTheme.accentColor)
                    Spacer()
                }
                .padding(.vertical)
            } else if let response = currentlyPlaying, let track = response.item {
                // Currently playing track
                VStack(spacing: 10) {
                    HStack(spacing: 15) {
                        // Album art
                        AsyncImage(url: URL(string: track.album.images.first?.url ?? "")) { image in
                            image.resizable()
                        } placeholder: {
                            ZStack {
                                themeManager.currentTheme.secondaryBackgroundColor
                                ProgressView()
                            }
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .id(track.id) // Force re-render only when track changes
                        
                        // Track info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.name)
                                .font(.headline)
                                .lineLimit(1)
                            Text(track.artists.first?.name ?? "Unknown Artist")
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Journal button
                        Button(action: {
                            let song = Song(
                                id: track.id,
                                title: track.name,
                                artist: track.artists.first?.name ?? "Unknown",
                                albumArtURL: track.album.images.first?.url
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
                    
                    // Progress bar and time
                    VStack(spacing: 4) {
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                Rectangle()
                                    .fill(themeManager.currentTheme.secondaryBackgroundColor)
                                    .frame(height: 4)
                                    .cornerRadius(2)
                                
                                // Progress
                                Rectangle()
                                    .fill(response.is_playing ? themeManager.currentTheme.accentColor : themeManager.currentTheme.secondaryTextColor)
                                    .frame(width: geometry.size.width * currentProgress, height: 4)
                                    .cornerRadius(2)
                                    .animation(.linear(duration: 0.5), value: currentProgress)
                            }
                        }
                        .frame(height: 4)
                        
                        // Time labels
                        HStack {
                            Text(formatTime(milliseconds: displayedProgressMs))
                                .font(.caption2)
                                .monospacedDigit()
                            Spacer()
                            Text(formatTime(milliseconds: track.duration_ms))
                                .font(.caption2)
                                .monospacedDigit()
                        }
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                .transition(.opacity) // Smooth transition when track changes
            } else {
                // Nothing playing
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "music.note.list")
                            .font(.title)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        Text("Nothing playing")
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
            Task {
                await fetchCurrentlyPlaying()
                startAutoRefresh()
            }
        }
        .onDisappear {
            stopAllTasks()
        }
    }
    
    // MARK: - API Call
    
    @MainActor
    private func fetchCurrentlyPlaying() async {
        // Silent background refresh - no loading indicator
        let newData = await SpotifyAPIManager.shared.getCurrentlyPlaying()
        
        // Check if anything actually changed
        let trackChanged = newData?.item?.id != previousTrackId
        let playStateChanged = newData?.is_playing != previousIsPlaying
        
        if trackChanged {
            print("🎵 Track changed: \(newData?.item?.name ?? "None")")
        }
        if playStateChanged {
            print("⏯️ Play state changed: \(newData?.is_playing == true ? "Playing" : "Paused")")
        }
        
        // Only update UI if something changed OR it's initial load
        if isInitialLoad || trackChanged || playStateChanged {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentlyPlaying = newData
                lastFetchTime = Date.now
                
                // Update tracking variables
                previousTrackId = newData?.item?.id
                previousIsPlaying = newData?.is_playing
                
                // Update progress immediately
                if let response = newData,
                   let progress = response.progress_ms,
                   let duration = response.item?.duration_ms,
                   duration > 0 {
                    displayedProgressMs = progress
                    currentProgress = Double(progress) / Double(duration)
                } else {
                    displayedProgressMs = 0
                    currentProgress = 0.0
                }
                
                isInitialLoad = false
            }
            
            // Start/restart progress updates if playing
            if newData?.is_playing == true {
                startProgressUpdates()
            } else {
                stopProgressUpdates()
            }
        } else {
            // Silent sync - just update the fetch time and progress position
            lastFetchTime = Date.now
            if let response = newData,
               let progress = response.progress_ms {
                displayedProgressMs = progress
                if let duration = response.item?.duration_ms, duration > 0 {
                    currentProgress = Double(progress) / Double(duration)
                }
            }
            print("🔄 Background sync - no UI changes needed")
        }
    }
    
    // MARK: - Progress Updates (Local - No API Calls)
    
    @MainActor
    private func startProgressUpdates() {
        // Cancel existing task
        progressTask?.cancel()
        
        // Start new progress update task (updates UI every second locally)
        progressTask = Task {
            while !Task.isCancelled {
                // Wait 1 second
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                guard !Task.isCancelled else { break }
                
                // Update progress locally (no API call)
                if let response = currentlyPlaying,
                   response.is_playing,
                   let initialProgress = response.progress_ms,
                   let duration = response.item?.duration_ms,
                   duration > 0,
                   let fetchTime = lastFetchTime {
                    
                    // Calculate elapsed time since last fetch
                    let elapsedSinceFetch = Date.now.timeIntervalSince(fetchTime)
                    let estimatedProgress = initialProgress + Int(elapsedSinceFetch * 1000)
                    
                    // Update displayed values
                    displayedProgressMs = min(estimatedProgress, duration)
                    currentProgress = min(Double(estimatedProgress) / Double(duration), 1.0)
                    
                    // If song is about to end (within 2 seconds), fetch next track
                    if displayedProgressMs >= duration - 2000 && displayedProgressMs < duration {
                        print("🔄 Song ending soon, fetching next track...")
                        await fetchCurrentlyPlaying()
                        break
                    }
                }
            }
        }
    }
    
    @MainActor
    private func stopProgressUpdates() {
        progressTask?.cancel()
        progressTask = nil
    }
    
    // MARK: - Auto Refresh (API Calls Every 5 Seconds)
    
    @MainActor
    private func startAutoRefresh() {
        // Cancel existing task
        refreshTask?.cancel()
        
        // Start new refresh task - API call every 5 seconds
        refreshTask = Task {
            while !Task.isCancelled {
                // Wait 5 seconds
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                
                guard !Task.isCancelled else { break }
                
                // Background refresh (silent)
                await fetchCurrentlyPlaying()
            }
        }
    }
    
    @MainActor
    private func stopAllTasks() {
        progressTask?.cancel()
        refreshTask?.cancel()
        progressTask = nil
        refreshTask = nil
        print("🛑 Stopped all widget tasks")
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(milliseconds: Int) -> String {
        let totalSeconds = milliseconds / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
