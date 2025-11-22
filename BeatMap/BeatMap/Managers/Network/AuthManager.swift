// MARK: - File Header
//
// AuthManager.swift
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
import Combine
import OAuthSwift
import CryptoKit
#if os(iOS)
import SafariServices
import UIKit
#endif

/// Manages user authentication with Spotify using OAuth 2.0 PKCE flow.
/// Handles token storage, refresh, and session management for BeatMap.
class AuthManager: NSObject, ObservableObject {

    // MARK: - Properties
    
    static let shared = AuthManager()

    @Published var authState: AuthState = .loggedOut
    @Published var recentlyPlayedHistory: [PlayHistoryObject] = []
    @Published var errorMessage: String?

    private(set) var accessToken: String? {
        didSet {
            SpotifyAPIManager.shared.setAccessToken(accessToken)
            print("🔑 Access token \(accessToken != nil ? "set" : "cleared").")
        }
    }
    private var refreshToken: String?
    private var isRefreshing = false
    private var oauthSwift: OAuth2Swift?

    // Keychain identifiers - namespaced for BeatMap
    private let accessTokenService = "com.beatmap.spotify-access-token"
    private let refreshTokenService = "com.beatmap.spotify-refresh-token"
    private let keychainAccount = "spotify"

    enum AuthState {
        case checking, loggedOut, loggingIn, onboarding, loggedIn
    }

    private override init() {
        super.init()
        setupOAuthSwift()
        checkForSavedToken()
        LogManager.shared.log("AuthManager initialized", level: .success)
    }

    // MARK: - OAuth Setup
    
    private func setupOAuthSwift() {
        let clientID = SpotifyCredentials.clientID
        let redirectURI = SpotifyCredentials.redirectURI
        
        guard !clientID.isEmpty, !redirectURI.isEmpty else {
            print("❌ Cannot initialize OAuth: Missing Client ID or Redirect URI")
            DispatchQueue.main.async {
                self.errorMessage = "App configuration error: Missing credentials."
            }
            return
        }

        self.oauthSwift = OAuth2Swift(
            consumerKey: clientID,
            consumerSecret: "",
            authorizeUrl: "https://accounts.spotify.com/authorize",
            accessTokenUrl: "https://accounts.spotify.com/api/token",
            responseType: "code"
        )
        
        self.oauthSwift?.allowMissingStateCheck = true
        print("✅ OAuth instance created")
    }
    
    private func setupSafariHandler() {
        #if os(iOS)
        guard let oauthSwift = self.oauthSwift else { return }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            oauthSwift.authorizeURLHandler = SafariURLHandler(viewController: rootViewController, oauthSwift: oauthSwift)
            print("✅ Safari handler configured")
        } else {
            print("⚠️ Could not get root view controller")
        }
        #endif
    }

    // MARK: - Public Methods

    func loginWithSpotify() {
        guard let oauthSwift = self.oauthSwift else {
            print("❌ OAuth not initialized")
            DispatchQueue.main.async {
                self.errorMessage = "Auth service not initialized."
            }
            return
        }

        setupSafariHandler()

        print("🚀 Initiating Spotify login...")
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.authState = .loggingIn
        }

        let scope = "user-read-recently-played user-read-private user-read-email user-read-currently-playing user-read-playback-state"
        let state = generateState()
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)

        oauthSwift.authorize(
            withCallbackURL: URL(string: SpotifyCredentials.redirectURI)!,
            scope: scope,
            state: state,
            codeChallenge: codeChallenge,
            codeChallengeMethod: "S256",
            codeVerifier: codeVerifier,
            parameters: [:],
            headers: nil
        ) { result in
            DispatchQueue.main.async {
                self.handleLoginCompletion(result: result)
            }
        }
    }
    
    @MainActor
    private func handleLoginCompletion(result: Result<OAuthSwift.TokenSuccess, OAuthSwiftError>) {
        switch result {
        case .success(let tokenSuccess):
            let credential = tokenSuccess.credential

            print("✅ Spotify authorization successful!")
            LogManager.shared.log("Spotify login successful", level: .success)
            print("   Access Token: \(credential.oauthToken.prefix(10))...")
            print("   Refresh Token: \(credential.oauthRefreshToken.isEmpty ? "No" : "Yes")")

            self.saveTokenToKeychain(token: credential.oauthToken, service: self.accessTokenService)
            self.accessToken = credential.oauthToken

            if !credential.oauthRefreshToken.isEmpty {
                self.saveTokenToKeychain(token: credential.oauthRefreshToken, service: self.refreshTokenService)
                self.refreshToken = credential.oauthRefreshToken
                print("✅ Tokens saved to Keychain")
            }

            Task {
                await self.fetchRecentlyPlayed()
                if self.authState == .loggingIn {
                    self.authState = .onboarding
                }
            }

        case .failure(let error):
            print("❌ Spotify authorization failed: \(error.localizedDescription)")
            LogManager.shared.log("Spotify login failed: \(error.localizedDescription)", level: .error)
            self.errorMessage = "Spotify login failed: \(error.localizedDescription)"
            self.authState = .loggedOut
        }
    }

    private func generateState(withLength len: Int = 20) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<len).map{ _ in letters.randomElement()! })
    }

    @MainActor
    func completeOnboarding() {
        print("🎉 Onboarding complete")
        authState = .loggedIn
    }

    @MainActor
    func logout() {
        print("🚪 Logging out")
        deleteTokensFromKeychain()
        self.accessToken = nil
        self.refreshToken = nil
        self.recentlyPlayedHistory = []
        self.authState = .loggedOut
    }

    @MainActor
    func clearError() {
        self.errorMessage = nil
    }

    // MARK: - Token Refresh

    @MainActor
    func refreshToken() async -> Bool {
        guard !isRefreshing else {
            print("⏳ Token refresh in progress...")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            return accessToken != nil
        }
        
        guard let oauthSwift = self.oauthSwift else {
            print("❌ Cannot refresh: OAuth not initialized")
            await logout()
            return false
        }
        
        guard let currentRefreshToken = self.refreshToken else {
            print("❌ Cannot refresh: No refresh token")
            await logout()
            return false
        }

        print("♻️ Refreshing access token...")
        isRefreshing = true

        return await withCheckedContinuation { continuation in
            oauthSwift.renewAccessToken(withRefreshToken: currentRefreshToken) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let tokenSuccess):
                        let credential = tokenSuccess.credential
                        
                        print("✅ Token refreshed")
                        self.saveTokenToKeychain(token: credential.oauthToken, service: self.accessTokenService)
                        self.accessToken = credential.oauthToken

                        if !credential.oauthRefreshToken.isEmpty && credential.oauthRefreshToken != currentRefreshToken {
                            self.saveTokenToKeychain(token: credential.oauthRefreshToken, service: self.refreshTokenService)
                            self.refreshToken = credential.oauthRefreshToken
                        }
                        
                        self.isRefreshing = false
                        continuation.resume(returning: true)

                    case .failure(let error):
                        print("❌ Token refresh failed: \(error.localizedDescription)")
                        Task { await self.logout() }
                        self.isRefreshing = false
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    // MARK: - PKCE Helpers

    /// Generates a 43-character URL-safe random string for PKCE code verifier
    private func generateCodeVerifier() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<43).map{ _ in letters.randomElement()! })
    }

    /// Generates SHA256 hash of verifier as Base64 URL-encoded code challenge
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else {
            fatalError("Could not encode verifier to UTF-8")
        }
        
        let hashed = SHA256.hash(data: data)
        let hashedData = Data(hashed)
        
        let base64 = hashedData.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // MARK: - Keychain Storage

    private func checkForSavedToken() {
        print("🔍 Checking for saved tokens...")
        authState = .checking
        self.accessToken = loadTokenFromKeychain(service: accessTokenService)
        self.refreshToken = loadTokenFromKeychain(service: refreshTokenService)
        
        if self.accessToken != nil {
            print("🔑 Found saved access token")
            Task { await fetchRecentlyPlayed() }
        } else if self.refreshToken != nil {
            print("♻️ Found refresh token, attempting refresh...")
            Task {
                if await refreshToken() {
                    await fetchRecentlyPlayed()
                } else if self.authState == .checking {
                    DispatchQueue.main.async { self.authState = .loggedOut }
                }
            }
        } else {
            print("🚫 No saved tokens found")
            DispatchQueue.main.async { self.authState = .loggedOut }
        }
    }

    private func saveTokenToKeychain(token: String, service: String) {
        guard let data = token.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            print("❌ Error saving token to Keychain: \(status)")
            return
        }
    }

    private func loadTokenFromKeychain(service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }

    private func deleteTokensFromKeychain() {
        let accessTokenQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: accessTokenService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        let refreshTokenQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: refreshTokenService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        SecItemDelete(accessTokenQuery as CFDictionary)
        SecItemDelete(refreshTokenQuery as CFDictionary)
    }

    // MARK: - Spotify API

    @MainActor
    private func fetchRecentlyPlayed() async {
        guard accessToken != nil || refreshToken != nil else {
            if authState == .checking {
                print("🚫 No tokens available")
                DispatchQueue.main.async { self.authState = .loggedOut }
            }
            return
        }

        print("🎵 Fetching recently played tracks...")
        
        guard let url = URL(string: "https://api.spotify.com/v1/me/player/recently-played") else {
            print("❌ Invalid URL")
            if authState == .checking { await logout() }
            return
        }
        
        let request = URLRequest(url: url)
        let result: RecentlyPlayedResponse? = await SpotifyAPIManager.shared.makeAPIRequest(request: request)

        if let result = result {
            self.recentlyPlayedHistory = result.items
            print("✅ Fetched \(self.recentlyPlayedHistory.count) tracks")
            
            if self.authState == .checking {
                self.authState = .loggedIn
            } else if self.authState == .loggingIn {
                self.authState = .onboarding
            }
        } else {
            print("❌ Failed to fetch tracks")
            
            if authState == .checking {
                await logout()
            } else if authState == .loggingIn {
                DispatchQueue.main.async {
                    self.errorMessage = "Logged in, but failed to fetch recent tracks."
                    self.authState = .onboarding
                }
            }
        }
    }
}
