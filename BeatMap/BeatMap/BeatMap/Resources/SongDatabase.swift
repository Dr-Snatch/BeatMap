// MARK: - File Header
//
// SongDatabase.swift
// BeatMap
//
// Version: 1.0.0
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import Foundation

/// A simulated database of songs for picking, identifying, and use as sample data.
/// This provides demo content while the full Spotify integration is being used.
struct SongDatabase {
    
    // MARK: - Sample Songs
    
    /// Collection of sample songs available in BeatMap.
    /// Uses `albumArtSymbol` with SF Symbols for visual representation.
    static let allSongs: [Song] = [
        Song(id: "1", title: "Vienna", artist: "Billy Joel", albumArtSymbol: "music.mic"),
        Song(id: "2", title: "Here Comes The Sun", artist: "The Beatles", albumArtSymbol: "sun.max.fill"),
        Song(id: "3", title: "As It Was", artist: "Harry Styles", albumArtSymbol: "record.circle"),
        Song(id: "4", title: "Ribs", artist: "Lorde", albumArtSymbol: "waveform"),
        Song(id: "5", title: "Bohemian Rhapsody", artist: "Queen", albumArtSymbol: "guitars"),
        Song(id: "6", title: "Smells Like Teen Spirit", artist: "Nirvana", albumArtSymbol: "bolt.fill"),
        Song(id: "7", title: "All Too Well (10 Min Version)", artist: "Taylor Swift", albumArtSymbol: "text.book.closed.fill"),
        Song(id: "8", title: "Good Days", artist: "SZA", albumArtSymbol: "cloud.sun.fill"),
        Song(id: "9", title: "Stairway to Heaven", artist: "Led Zeppelin", albumArtSymbol: "flame.fill"),
        Song(id: "10", title: "Blinding Lights", artist: "The Weeknd", albumArtSymbol: "light.max"),
        Song(id: "11", title: "Hotel California", artist: "Eagles", albumArtSymbol: "building.columns.fill"),
        Song(id: "12", title: "Rolling in the Deep", artist: "Adele", albumArtSymbol: "wind")
    ]
    
    // MARK: - Helper Methods
    
    /// Simulates song identification by returning a random song from the database.
    /// Used for demo/fallback when Shazam is unavailable.
    /// - Returns: A randomly selected song from the sample database
    static func identifyRandomSong() -> Song {
        // Safe force unwrap as allSongs is never empty
        allSongs.randomElement()!
    }
}
