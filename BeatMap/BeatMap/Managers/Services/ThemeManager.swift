// MARK: - File Header
//
// ThemeManager.swift
// BeatMap
//
// Version: 2.0.0 (Expanded Themes)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI
import Combine

/// Available color themes for BeatMap.
/// Each theme provides a cohesive color palette for the entire app.
enum Theme: String, CaseIterable, Identifiable {
    case midnightVinyl = "Midnight Vinyl"
    case fadedPhotograph = "Faded Photograph"
    case daydream = "Daydream"
    case sunsetGroove = "Sunset Groove"
    case oceanWave = "Ocean Wave"
    case neonNights = "Neon Nights"
    case cherryBlossom = "Cherry Blossom"
    case mocha = "Mocha"
    
    var id: String { self.rawValue }
    
    // MARK: - Background Colors
    
    var primaryBackgroundColor: Color {
        switch self {
        case .midnightVinyl:
            return Color(red: 18/255, green: 18/255, blue: 18/255) // Dark charcoal
        case .fadedPhotograph:
            return Color(red: 248/255, green: 245/255, blue: 240/255) // Warm cream
        case .daydream:
            return .white
        case .sunsetGroove:
            return Color(red: 26/255, green: 24/255, blue: 44/255) // Deep purple-blue
        case .oceanWave:
            return Color(red: 15/255, green: 52/255, blue: 67/255) // Deep ocean blue
        case .neonNights:
            return Color(red: 10/255, green: 10/255, blue: 15/255) // Almost black
        case .cherryBlossom:
            return Color(red: 255/255, green: 250/255, blue: 250/255) // Soft white-pink
        case .mocha:
            return Color(red: 240/255, green: 235/255, blue: 229/255) // Light coffee cream
        }
    }
    
    var secondaryBackgroundColor: Color {
        switch self {
        case .midnightVinyl:
            return Color(red: 55/255, green: 55/255, blue: 55/255) // Lighter grey
        case .fadedPhotograph:
            return Color(red: 230/255, green: 225/255, blue: 218/255) // Light beige
        case .daydream:
            return Color.gray.opacity(0.1) // Very light grey
        case .sunsetGroove:
            return Color(red: 44/255, green: 38/255, blue: 66/255) // Lighter purple
        case .oceanWave:
            return Color(red: 28/255, green: 73/255, blue: 94/255) // Medium ocean blue
        case .neonNights:
            return Color(red: 25/255, green: 25/255, blue: 35/255) // Dark grey-blue
        case .cherryBlossom:
            return Color(red: 255/255, green: 235/255, blue: 238/255) // Light pink
        case .mocha:
            return Color(red: 218/255, green: 207/255, blue: 195/255) // Medium coffee
        }
    }

    // MARK: - Text Colors
    
    var primaryTextColor: Color {
        switch self {
        case .midnightVinyl, .sunsetGroove, .oceanWave, .neonNights:
            return .white
        case .fadedPhotograph:
            return Color(red: 50/255, green: 50/255, blue: 50/255) // Dark grey-brown
        case .daydream:
            return .black
        case .cherryBlossom:
            return Color(red: 60/255, green: 50/255, blue: 55/255) // Soft dark pink-brown
        case .mocha:
            return Color(red: 64/255, green: 50/255, blue: 40/255) // Coffee brown
        }
    }
    
    var secondaryTextColor: Color {
        switch self {
        case .midnightVinyl, .sunsetGroove, .oceanWave, .neonNights:
            return .gray
        case .fadedPhotograph:
            return Color(red: 120/255, green: 110/255, blue: 100/255) // Medium grey-brown
        case .daydream:
            return .gray
        case .cherryBlossom:
            return Color(red: 160/255, green: 140/255, blue: 150/255) // Muted pink-grey
        case .mocha:
            return Color(red: 140/255, green: 120/255, blue: 100/255) // Light coffee brown
        }
    }
    
    // MARK: - Accent Color
    
    var accentColor: Color {
        switch self {
        case .midnightVinyl:
            return .blue
        case .fadedPhotograph:
            return Color(red: 200/255, green: 90/255, blue: 40/255) // Burnt orange
        case .daydream:
            return .mint
        case .sunsetGroove:
            return Color(red: 255/255, green: 107/255, blue: 107/255) // Coral pink
        case .oceanWave:
            return Color(red: 52/255, green: 211/255, blue: 235/255) // Bright cyan
        case .neonNights:
            return Color(red: 0/255, green: 255/255, blue: 157/255) // Neon green
        case .cherryBlossom:
            return Color(red: 255/255, green: 105/255, blue: 180/255) // Hot pink
        case .mocha:
            return Color(red: 139/255, green: 90/255, blue: 60/255) // Rich brown
        }
    }
    
    // MARK: - Color Scheme
    
    var colorScheme: ColorScheme {
        switch self {
        case .midnightVinyl, .sunsetGroove, .oceanWave, .neonNights:
            return .dark
        case .fadedPhotograph, .daydream, .cherryBlossom, .mocha:
            return .light
        }
    }
    
    // MARK: - Theme Description
    
    var description: String {
        switch self {
        case .midnightVinyl:
            return "Classic dark mode with blue accents"
        case .fadedPhotograph:
            return "Vintage warm tones inspired by old photos"
        case .daydream:
            return "Clean and minimal light theme"
        case .sunsetGroove:
            return "Deep purple nights with coral highlights"
        case .oceanWave:
            return "Deep blue waters with cyan accents"
        case .neonNights:
            return "Cyberpunk dark with neon green"
        case .cherryBlossom:
            return "Soft pink aesthetic with hot pink accents"
        case .mocha:
            return "Coffee shop vibes with rich brown tones"
        }
    }
    
    // MARK: - Theme Icon
    
    var icon: String {
        switch self {
        case .midnightVinyl:
            return "record.circle.fill"
        case .fadedPhotograph:
            return "photo.fill"
        case .daydream:
            return "sun.max.fill"
        case .sunsetGroove:
            return "sunset.fill"
        case .oceanWave:
            return "water.waves"
        case .neonNights:
            return "sparkles"
        case .cherryBlossom:
            return "leaf.fill"
        case .mocha:
            return "cup.and.saucer.fill"
        }
    }
}

/// Manages BeatMap's visual theme and persists user preferences.
/// Allows users to switch between different color schemes throughout the app.
class ThemeManager: ObservableObject {
    
    /// The user's selected theme, persisted in UserDefaults
    @AppStorage("beatmap.selectedTheme") var selectedThemeRawValue: String = Theme.midnightVinyl.rawValue
    
    /// The currently active theme
    @Published var currentTheme: Theme
    
    init() {
        // Load saved theme from UserDefaults
        let savedThemeRawValue = UserDefaults.standard.string(forKey: "beatmap.selectedTheme") ?? Theme.midnightVinyl.rawValue
        self.currentTheme = Theme(rawValue: savedThemeRawValue) ?? .midnightVinyl
        print("✅ ThemeManager initialized. Current theme: \(currentTheme.rawValue)")
    }
    
    /// Updates the active theme and saves the selection
    /// - Parameter theme: The new theme to apply
    func setTheme(_ theme: Theme) {
        currentTheme = theme
        selectedThemeRawValue = theme.rawValue
        print("🎨 Theme changed to: \(theme.rawValue)")
    }
}
