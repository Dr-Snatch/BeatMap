// MARK: - File Header
//
// SpotifyAPIManager.swift
// BeatMap
//
// Version: 1.1.0 (Improved 204 Handling)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import Foundation
import Combine

/// Manages all Spotify API requests with automatic token refresh.
/// Works in conjunction with AuthManager to handle authentication and token lifecycle.
class SpotifyAPIManager: ObservableObject {

    static let shared = SpotifyAPIManager()
    private var accessToken: String?

    /// Updates the access token used for API requests
    /// Called by AuthManager when tokens are refreshed or updated
    func setAccessToken(_ token: String?) {
        self.accessToken = token
        print("API Manager: Access token \(token != nil ? "updated" : "cleared").")
    }

    // MARK: - Generic API Request Handler

    /// Generic function to handle all Spotify API requests with automatic token refresh
    @MainActor
    internal func makeAPIRequest<T: Decodable>(request: URLRequest) async -> T? {
        // Ensure we have a token
        guard let currentAccessToken = accessToken else {
            print("❌ No access token available")
            
            // Attempt immediate refresh if no token exists
            let refreshSuccess = await AuthManager.shared.refreshToken()
            guard refreshSuccess, let newAccessToken = AuthManager.shared.accessToken else {
                print("❌ Refresh failed")
                if AuthManager.shared.authState != .loggedOut {
                    await AuthManager.shared.logout()
                }
                return nil
            }
            
            print("✅ Token refreshed, retrying request")
            return await makeAPIRequest(request: request) // Retry with new token
        }

        var urlRequest = request
        urlRequest.setValue("Bearer \(currentAccessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response")
                return nil
            }

            // Handle 401 Unauthorized (expired token)
            if httpResponse.statusCode == 401 {
                print("🔄 Token expired, refreshing...")
                let refreshSuccess = await AuthManager.shared.refreshToken()

                if refreshSuccess {
                    guard let newAccessToken = AuthManager.shared.accessToken else {
                        print("❌ Failed to get new token")
                        return nil
                    }

                    // Retry request with new token
                    var newUrlRequest = request
                    newUrlRequest.setValue("Bearer \(newAccessToken)", forHTTPHeaderField: "Authorization")

                    let (newData, newResponse) = try await URLSession.shared.data(for: newUrlRequest)

                    guard let newHttpResponse = newResponse as? HTTPURLResponse,
                          newHttpResponse.statusCode == 200 else {
                        print("❌ Retry failed: \((newResponse as? HTTPURLResponse)?.statusCode ?? 0)")
                        if (newResponse as? HTTPURLResponse)?.statusCode == 401 ||
                           (newResponse as? HTTPURLResponse)?.statusCode == 403 {
                            await AuthManager.shared.logout()
                        }
                        return nil
                    }

                    print("✅ Request successful after refresh")
                    return try JSONDecoder().decode(T.self, from: newData)

                } else {
                    print("❌ Token refresh failed")
                    return nil
                }
            }

            // Handle 204 No Content (this is normal for some endpoints like currently-playing when nothing is playing)
            if httpResponse.statusCode == 204 {
                print("ℹ️ API returned 204 No Content (normal when nothing is playing)")
                return nil
            }
            
            // Handle other non-200 status codes
            guard httpResponse.statusCode == 200 else {
                print("❌ API error: Status \(httpResponse.statusCode)")
                if let responseBody = String(data: data, encoding: .utf8) {
                    print("   Response: \(responseBody)")
                }
                // Only logout on 401 (unauthorized) or persistent auth failures
                // Don't logout on 403 for specific endpoints (like audio features)
                // which might have dev mode restrictions
                if httpResponse.statusCode == 401 {
                    print("⚠️ 401 Unauthorized - will attempt refresh on next request")
                }
                return nil
            }

            // Success - decode and return
            print("✅ API request successful")
            return try JSONDecoder().decode(T.self, from: data)

        } catch {
            print("❌ API request error: \(error)")
            return nil
        }
    }

    // MARK: - Public API Methods

    /// Search for tracks on Spotify
    @MainActor
    func searchForTracks(query: String) async -> [TrackObject] {
        print("🔍 Searching Spotify: '\(query)'")
        guard !query.isEmpty else { return [] }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/search"
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "track"),
            URLQueryItem(name: "limit", value: "20")
        ]

        guard let url = components.url else {
            print("❌ Invalid search URL")
            return []
        }
        
        let request = URLRequest(url: url)
        let searchResult: SpotifySearchResult? = await makeAPIRequest(request: request)

        let tracks = searchResult?.tracks.items ?? []
        print("✅ Found \(tracks.count) tracks")
        return tracks
    }

    /// Fetch audio features for a specific track
    @MainActor
    func getAudioFeatures(for trackId: String) async -> AudioFeatures? {
        print("📊 Fetching audio features: \(trackId)")
        
        guard let url = URL(string: "https://api.spotify.com/v1/audio-features/\(trackId)") else {
            print("❌ Invalid URL")
            return nil
        }
        
        let request = URLRequest(url: url)
        let features: AudioFeatures? = await makeAPIRequest(request: request)
        
        if features != nil {
            print("✅ Audio features fetched")
        }
        return features
    }

    /// Fetch artist details including genres
    @MainActor
    func getArtistDetails(for artistId: String) async -> ArtistDetail? {
        print("🧑‍🎤 Fetching artist details: \(artistId)")
        
        guard let url = URL(string: "https://api.spotify.com/v1/artists/\(artistId)") else {
            print("❌ Invalid URL")
            return nil
        }
        
        let request = URLRequest(url: url)
        let artist: ArtistDetail? = await makeAPIRequest(request: request)
        
        if let artist = artist {
            print("✅ Artist details fetched. Genres: \(artist.genres?.joined(separator: ", ") ?? "None")")
        }
        return artist
    }
    
    /// Fetch the user's currently playing track
    @MainActor
    func getCurrentlyPlaying() async -> CurrentlyPlayingResponse? {
        print("🎵 Fetching currently playing track...")
        
        guard let url = URL(string: "https://api.spotify.com/v1/me/player/currently-playing") else {
            print("❌ Invalid URL")
            return nil
        }
        
        let request = URLRequest(url: url)
        let response: CurrentlyPlayingResponse? = await makeAPIRequest(request: request)
        
        if let response = response, response.is_playing {
            print("✅ Currently playing: \(response.item?.name ?? "Unknown")")
        } else {
            print("ℹ️ No track currently playing")
        }
        
        return response
    }
}
