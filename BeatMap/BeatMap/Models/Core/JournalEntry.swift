// MARK: - File Header
//
// JournalEntry.swift
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

/// Represents a single music journal entry in BeatMap.
/// Combines personal reflections with location data and comprehensive Spotify audio analysis.
struct JournalEntry: Identifiable, Codable, Equatable {
    
    // MARK: - Core Properties
    
    let id: UUID
    let song: Song
    let journalText: String
    
    // MARK: - Location Data
    
    let location: String
    let latitude: Double
    let longitude: Double
    
    // MARK: - Temporal Data
    
    let date: Date
    
    // MARK: - User Metrics
    
    let nostalgiaValue: Double  // User's nostalgia rating (0-100)
    let energyValue: Double     // User's perceived energy (0-100)
    let moodValue: Double       // User's mood rating (0-100)
    
    // MARK: - Context
    
    let isLivePerformance: Bool
    let activity: String?       // What the user was doing
    let company: String?        // Who the user was with
    
    // MARK: - Spotify Audio Features
    
    let genre: String?          // Primary genre from artist
    let tempo: Double?          // Beats per minute (BPM)
    let spotifyEnergy: Double?  // Spotify's energy calculation (0.0-1.0)
    let danceability: Double?   // How suitable for dancing (0.0-1.0)
    let valence: Double?        // Musical positiveness (0.0-1.0)
    let acousticness: Double?   // Confidence it's acoustic (0.0-1.0)
    
    // MARK: - Extended Audio Features
    
    let instrumentalness: Double? // Likelihood of no vocals (0.0-1.0)
    let liveness: Double?         // Presence of audience (0.0-1.0)
    let speechiness: Double?      // Amount of spoken words (0.0-1.0)
    let key: Int?                 // Musical key (0=C, 1=C#, ..., 11=B)
    let mode: Int?                // Modality (0=Minor, 1=Major)
    let timeSignature: Int?       // Time signature (e.g., 4 for 4/4)
    let loudness: Double?         // Overall loudness in dB
    let durationMs: Int?          // Track duration in milliseconds
    
    // MARK: - Computed Properties
    
    /// Formatted date string for display
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
