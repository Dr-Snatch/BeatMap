// MARK: - File Header
//
// SpotifyCredentials.swift
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

/// Centralized Spotify API credentials for BeatMap's OAuth 2.0 PKCE flow.
/// These values must match exactly what's configured in the Spotify Developer Dashboard.
struct SpotifyCredentials {

    /// Your unique application identifier from the Spotify Developer Dashboard
    /// ⚠️ Keep this private - do not commit to public repositories
    static let clientID = "95bc532496e647e293c45b84f8ec87f0"
    
    /// The Redirect URI configured in your Spotify Developer Dashboard
    /// ⚠️ Must exactly match the dashboard setting
    static let redirectURI = "beatmap://callback"
    
    // IMPORTANT NOTES:
    // 1. Client Secret is NOT used in PKCE flow (mobile apps use code_challenge instead)
    // 2. The redirect URI "beatmap://callback" must be registered in:
    //    - Spotify Developer Dashboard (https://developer.spotify.com/dashboard)
    //    - Info.plist (CFBundleURLSchemes = "beatmap")
    // 3. Any changes to these values require:
    //    - Updating Spotify Dashboard
    //    - Clean build in Xcode
    //    - Re-authentication by users
}
