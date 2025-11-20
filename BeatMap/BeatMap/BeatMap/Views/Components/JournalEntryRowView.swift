// MARK: - File Header
//
// JournalEntryRowView.swift
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

/// Reusable row component displaying a journal entry summary.
/// Used in lists throughout BeatMap to show entry previews with album art, song info, and metadata.
struct JournalEntryRowView: View {
    
    // MARK: - Properties & Environment
    
    @EnvironmentObject var themeManager: ThemeManager
    let entry: JournalEntry
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 20) {
            // Large album artwork
            AlbumArtView(song: entry.song, size: 120)

            // Entry information
            VStack(alignment: .leading, spacing: 5) {
                // Song title
                Text(entry.song.title)
                    .fontWeight(.bold)
                    .font(.title2)
                
                // Artist name
                Text(entry.song.artist)
                    .font(.title3)
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                
                // Journal text preview (with empty state handling)
                if !entry.journalText.isEmpty {
                    Text(entry.journalText)
                        .font(.body)
                        .lineLimit(3)
                        .padding(.top, 4)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .font(.caption)
                        Text("Audio moment captured")
                            .font(.body)
                            .italic()
                    }
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                    .padding(.top, 4)
                }
                
                // Location and date
                Text("📍 \(entry.location) • \(entry.dateString)")
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                    .padding(.top, 8)
            }
            .foregroundStyle(themeManager.currentTheme.primaryTextColor)
            
            Spacer()
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.secondaryTextColor.opacity(0.5))
        }
        .padding(.vertical, 15)
    }
}

#Preview {
    PreviewContainer {
        JournalEntryRowView(entry: JournalStore.sampleEntries[0])
            .padding()
            .background(Color.gray)
    }
}
