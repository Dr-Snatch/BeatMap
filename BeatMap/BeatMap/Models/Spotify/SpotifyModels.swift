// MARK: - File Header
//
// SpotifyModels.swift
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

// MARK: - Recently Played Models

/// Top-level response from Spotify's "recently played" endpoint
/// Used in BeatMap's onboarding and authentication flow
struct RecentlyPlayedResponse: Codable {
    let items: [PlayHistoryObject]
}

/// Represents a single item in the user's play history
/// Identifiable using the unique timestamp for SwiftUI lists
struct PlayHistoryObject: Codable, Identifiable {
    let track: TrackObject
    let played_at: String
    
    var id: String { played_at }
}

// MARK: - Track Models

/// Core object representing a Spotify track
/// Identifiable for use in SwiftUI Lists and ForEach
struct TrackObject: Codable, Identifiable {
    let id: String
    let name: String
    let artists: [ArtistObject]
    let album: AlbumObject
}

/// Represents a single artist
/// Includes ID needed for fetching genre information
struct ArtistObject: Codable {
    let id: String
    let name: String
}

/// Represents an album with its associated images
struct AlbumObject: Codable {
    let images: [ImageObject]
}

/// Represents an image from Spotify's CDN
struct ImageObject: Codable {
    let url: String
}

// MARK: - Search Models

/// Top-level response from Spotify's search endpoint
struct SpotifySearchResult: Codable {
    let tracks: TrackSearchResult
}

/// Contains the array of tracks found in a search query
struct TrackSearchResult: Codable {
    let items: [TrackObject]
}

// MARK: - Audio Features Model

/// Comprehensive audio analysis from Spotify's audio features endpoint
/// Provides detailed metrics about a track's musical characteristics
/// Note: Uses snake_case to match Spotify's API response format
struct AudioFeatures: Codable {
    let id: String
    let tempo: Double?              // BPM
    let energy: Double?             // 0.0-1.0
    let danceability: Double?       // 0.0-1.0
    let valence: Double?            // Musical positiveness (0.0-1.0)
    let acousticness: Double?       // 0.0-1.0
    let instrumentalness: Double?   // 0.0-1.0
    let liveness: Double?           // Presence of audience (0.0-1.0)
    let speechiness: Double?        // Amount of spoken words (0.0-1.0)
    let key: Int?                   // 0=C, 1=C#, ..., 11=B
    let mode: Int?                  // 0=Minor, 1=Major
    let time_signature: Int?        // e.g., 4 for 4/4 time
    let loudness: Double?           // Overall loudness in dB
    let duration_ms: Int?           // Duration in milliseconds
}

// MARK: - Artist Details Model

/// Detailed artist information from Spotify's artist endpoint
/// Primary use: Retrieving genre information for journal entries
struct ArtistDetail: Codable {
    let id: String
    let name: String
    let genres: [String]?
}

// MARK: - Currently Playing Model

/// Full track object with duration (from currently playing endpoint)
struct FullTrackObject: Codable {
    let id: String
    let name: String
    let artists: [ArtistObject]
    let album: AlbumObject
    let duration_ms: Int
}

/// Response from Spotify's currently playing endpoint
struct CurrentlyPlayingResponse: Codable {
    let item: FullTrackObject?
    let is_playing: Bool
    let progress_ms: Int?
    
    /// Calculate playback progress as percentage (0.0 - 1.0)
    var progressPercentage: Double? {
        guard let progress = progress_ms,
              let duration = item?.duration_ms,
              duration > 0 else { return nil }
        return Double(progress) / Double(duration)
    }
}
