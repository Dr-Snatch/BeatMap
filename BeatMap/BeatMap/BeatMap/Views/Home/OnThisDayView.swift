// MARK: - File Header
//
// OnThisDayView.swift
// BeatMap
//
// Version: 1.1.0 (Fixed)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI

/// A card displayed on the home screen showing a journal entry from the same date in a previous year.
/// Creates nostalgic moments by surfacing memories tied to specific songs and places.
struct OnThisDayView: View {
    
    let entry: JournalEntry
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Card header
            Text("On This Day...")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.secondaryTextColor)

            // Tappable link to full entry detail
            NavigationLink(destination: JournalDetailView(entry: entry)) {
                HStack(spacing: 15) {
                    // Album art
                    AlbumArtView(song: entry.song, size: 60)
                        .environmentObject(themeManager)
                    
                    // Entry info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.song.title)
                            .fontWeight(.bold)
                            .font(.headline)
                            .lineLimit(1)
                        Text(entry.song.artist)
                            .font(.subheadline)
                            .lineLimit(1)
                        Text("\(entry.date.formatted(.dateTime.year())) • \(entry.location)")
                            .font(.caption)
                            .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Chevron indicator
                    Image(systemName: "chevron.right")
                        .foregroundStyle(themeManager.currentTheme.secondaryTextColor.opacity(0.7))
                }
            }
            .foregroundStyle(themeManager.currentTheme.primaryTextColor)
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    PreviewContainer {
        OnThisDayView(entry: JournalStore.sampleEntries[0])
            .padding()
    }
}
