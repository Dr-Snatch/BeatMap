// MARK: - File Header
//
// Song.swift
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

/// Represents a song in BeatMap's journal entries.
/// Flexible model supporting both live Spotify data and local sample data.
///
/// - Uses `albumArtURL` for real Spotify tracks with album artwork
/// - Uses `albumArtSymbol` for sample/demo tracks with SF Symbol icons
struct Song: Identifiable, Codable, Equatable, Hashable {
    
    let id: String          // Spotify Track ID or custom ID
    let title: String       // Song title
    let artist: String      // Artist name
    
    /// URL for album artwork from Spotify API (optional)
    var albumArtURL: String?
    
    /// SF Symbol name for placeholder artwork (optional)
    var albumArtSymbol: String?
}
