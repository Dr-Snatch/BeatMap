// MARK: - File Header
//
// JournalDetailView.swift
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
import MapKit

/// Displays the full details of a single journal entry.
/// Shows song info, location, journal text, and user metrics.
struct JournalDetailView: View {
    
    // MARK: - Environment & Properties
    
    @EnvironmentObject var themeManager: ThemeManager
    let entry: JournalEntry

    // MARK: - Body
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Song information
                    HStack(spacing: 15) {
                        AlbumArtView(song: entry.song, size: 80)
                        
                        VStack(alignment: .leading) {
                            Text(entry.song.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text(entry.song.artist)
                                .font(.title2)
                                .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 5) {
                        Label(entry.location, systemImage: "location.fill")
                        Label(entry.dateString, systemImage: "calendar")
                        
                        if entry.isLivePerformance {
                            Label("Live Performance", systemImage: "ticket.fill")
                                .foregroundStyle(themeManager.currentTheme.accentColor)
                        }
                        
                        if let activity = entry.activity {
                            Label("Activity: \(activity)", systemImage: "figure.walk")
                        }
                        
                        if let company = entry.company {
                            Label("Company: \(company)", systemImage: "person.2.fill")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                    
                    Divider()
                    
                    // Journal text (with empty state)
                    if !entry.journalText.isEmpty {
                        Text(entry.journalText)
                            .font(.body)
                            .lineSpacing(5)
                    } else {
                        HStack {
                            Image(systemName: "text.quote")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.5))
                            Text("No written notes for this moment")
                                .font(.body)
                                .italic()
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Divider()
                    
                    // User metrics
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Your Metrics")
                            .font(.headline)
                        
                        CustomSliderView(
                            label: "Nostalgia",
                            leftIcon: "hourglass",
                            rightIcon: "sparkles",
                            value: .constant(entry.nostalgiaValue)
                        )
                        
                        CustomSliderView(
                            label: "Energy",
                            leftIcon: "moon.zzz.fill",
                            rightIcon: "sun.max.fill",
                            value: .constant(entry.energyValue)
                        )
                        
                        CustomSliderView(
                            label: "Mood",
                            leftIcon: "hand.thumbsdown.fill",
                            rightIcon: "hand.thumbsup.fill",
                            value: .constant(entry.moodValue)
                        )
                    }
                    
                    // Display Spotify audio features if available
                    if let genre = entry.genre {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Song Details")
                                .font(.headline)
                            
                            HStack {
                                Label("Genre", systemImage: "music.quarternote.3")
                                Spacer()
                                Text(genre)
                            }
                            .font(.subheadline)
                            
                            if let tempo = entry.tempo {
                                HStack {
                                    Label("Tempo", systemImage: "metronome")
                                    Spacer()
                                    Text("\(Int(tempo)) BPM")
                                }
                                .font(.subheadline)
                            }
                            
                            if let energy = entry.spotifyEnergy {
                                HStack {
                                    Label("Energy", systemImage: "bolt.fill")
                                    Spacer()
                                    Text("\(Int(energy * 100))%")
                                }
                                .font(.subheadline)
                            }
                            
                            if let valence = entry.valence {
                                HStack {
                                    Label("Positivity", systemImage: "face.smiling")
                                    Spacer()
                                    Text("\(Int(valence * 100))%")
                                }
                                .font(.subheadline)
                            }
                            
                            if let danceability = entry.danceability {
                                HStack {
                                    Label("Danceability", systemImage: "figure.dance")
                                    Spacer()
                                    Text("\(Int(danceability * 100))%")
                                }
                                .font(.subheadline)
                            }
                        }
                        .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                }
                .padding()
            }
            .foregroundColor(themeManager.currentTheme.primaryTextColor)
            .navigationTitle(entry.song.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

#Preview {
    PreviewContainer {
        JournalDetailView(entry: JournalStore.sampleEntries[0])
    }
}
