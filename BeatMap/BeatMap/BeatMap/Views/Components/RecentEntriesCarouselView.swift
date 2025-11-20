// MARK: - File Header
//
// RecentEntriesCarouselView.swift
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

/// Horizontally scrolling carousel displaying recent journal entries.
/// Featured on the home screen to provide quick access to latest BeatMap moments.
struct RecentEntriesCarouselView: View {
    
    let entries: [JournalEntry]
    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading) {
            // Section header
            Text("Your Latest Entries")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)

            // Horizontal scrolling carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(entries) { entry in
                        NavigationLink(destination: JournalDetailView(entry: entry)) {
                            AlbumArtView(song: entry.song, size: 100)
                                .shadow(radius: 3)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 5)
            }
        }
    }
}

#Preview {
    PreviewContainer {
        RecentEntriesCarouselView(entries: Array(JournalStore.sampleEntries.prefix(5)))
            .padding(.vertical)
    }
}
