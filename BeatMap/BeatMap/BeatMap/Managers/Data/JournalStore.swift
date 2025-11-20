// MARK: - File Header
//
// JournalStore.swift
// BeatMap
//
// Version: 1.1.0 (Core Data Migration)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI
import Combine

/// Manages the collection of all journal entries for the BeatMap app.
/// Now uses Core Data for persistence with automatic migration from UserDefaults.
class JournalStore: ObservableObject {
    
    @Published var entries: [JournalEntry] = []
    
    private let coreDataManager = CoreDataManager.shared
    
    init() {
        print("🎯 Initializing JournalStore with Core Data...")
        
        // Perform migration from UserDefaults if needed
        coreDataManager.migrateFromUserDefaults()
        
        // Load entries from Core Data
        self.entries = coreDataManager.fetchAllEntries()
        
        print("✅ JournalStore initialized with \(entries.count) entries")
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new journal entry
    func addEntry(_ entry: JournalEntry) {
        // Save to Core Data
        coreDataManager.saveEntry(entry)
        
        // Update published array for UI reactivity
        entries.insert(entry, at: 0)
        
        print("✅ Entry added to store. Total entries: \(entries.count)")
    }
    
    /// Update an existing journal entry
    func updateEntry(_ entry: JournalEntry) {
        // Update in Core Data
        coreDataManager.updateEntry(entry)
        
        // Update published array for UI reactivity
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            print("✅ Entry updated in store: \(entry.song.title)")
        }
    }
    
    /// Delete entries at specific offsets
    func delete(at offsets: IndexSet) {
        // Delete from Core Data
        coreDataManager.deleteEntries(at: offsets, from: entries)
        
        // Update published array for UI reactivity
        entries.remove(atOffsets: offsets)
        
        print("🗑️ Entry deleted. Total entries: \(entries.count)")
    }
    
    /// Delete all journal entries
    func deleteAll() {
        // Delete from Core Data
        coreDataManager.deleteAllEntries()
        
        // Clear published array
        entries.removeAll()
        
        print("🗑️ All entries deleted from store")
    }
    
    /// Reload entries from Core Data (useful after external changes)
    func reloadEntries() {
        entries = coreDataManager.fetchAllEntries()
        print("🔄 Entries reloaded from Core Data: \(entries.count)")
    }
    
    // MARK: - Sample Data
    
    /// Rich sample journal entries with verified Spotify album artwork
    /// Note: These are now only used for previews, not for default data
    static let sampleEntries: [JournalEntry] = [
        JournalEntry(
            id: UUID(),
            song: Song(id: "2TVxnKdb3tqe1nhQWwwZCO", title: "Tiny Dancer", artist: "Elton John",
                      albumArtURL: "https://i.scdn.co/image/ab67616d00001e024ae1c4c5c45aabe565499163"),
            journalText: "Caught this on the radio during my morning coffee. The piano intro still gives me chills every time.",
            location: "Tynemouth Coffee Co., Newcastle",
            latitude: 55.0160, longitude: -1.4232,
            date: Date.now.addingTimeInterval(-86400 * 2),
            nostalgiaValue: 85, energyValue: 40, moodValue: 80,
            isLivePerformance: false, activity: "Relaxing", company: "Alone",
            genre: "Classic Rock", tempo: 76.0, spotifyEnergy: 0.4, danceability: 0.5, valence: 0.6,
            acousticness: 0.35, instrumentalness: 0.0, liveness: 0.1, speechiness: 0.03,
            key: 4, mode: 1, timeSignature: 4, loudness: -8.0, durationMs: 376000
        ),
        
        JournalEntry(
            id: UUID(),
            song: Song(id: "7oK9VyNzrYvRFo7nQEYkWN", title: "Mr. Brightside", artist: "The Killers",
                      albumArtURL: "https://i.scdn.co/image/ab67616d00001e02ccdddd46119a4ff53eaf1f5d"),
            journalText: "Classic night out tune. Everyone singing along at full volume. These are the moments.",
            location: "The Gate, Newcastle",
            latitude: 54.9691, longitude: -1.6104,
            date: Date.now.addingTimeInterval(-86400 * 5),
            nostalgiaValue: 70, energyValue: 95, moodValue: 90,
            isLivePerformance: false, activity: "Socializing", company: "Friends",
            genre: "Alternative Rock", tempo: 148.0, spotifyEnergy: 0.9, danceability: 0.5, valence: 0.4,
            acousticness: 0.01, instrumentalness: 0.0, liveness: 0.15, speechiness: 0.04,
            key: 1, mode: 1, timeSignature: 4, loudness: -5.0, durationMs: 223000
        ),
        
        JournalEntry(
            id: UUID(),
            song: Song(id: "39LLxExYz6ewLAcYrzQQyP", title: "Levitating", artist: "Dua Lipa",
                      albumArtURL: "https://i.scdn.co/image/ab67616d00001e02be841ba4bc24340152e3a79a"),
            journalText: "Perfect running track. Hit a new PR today - 5k in under 25 minutes! This song pushed me through the last kilometer.",
            location: "Jesmond Dene Park, Newcastle",
            latitude: 54.9897, longitude: -1.5946,
            date: Date.now.addingTimeInterval(-86400 * 7),
            nostalgiaValue: 30, energyValue: 100, moodValue: 95,
            isLivePerformance: false, activity: "Exercising", company: "Alone",
            genre: "Dance Pop", tempo: 103.0, spotifyEnergy: 0.7, danceability: 0.7, valence: 0.9,
            acousticness: 0.05, instrumentalness: 0.0, liveness: 0.1, speechiness: 0.05,
            key: 6, mode: 0, timeSignature: 4, loudness: -4.0, durationMs: 203000
        )
    ]
}
