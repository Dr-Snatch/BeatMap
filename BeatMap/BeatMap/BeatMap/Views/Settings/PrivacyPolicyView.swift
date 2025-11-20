// MARK: - File Header
//
// PrivacyPolicyView.swift
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

/// Displays BeatMap's Privacy Policy
/// This policy explains how user data is collected, used, and protected
struct PrivacyPolicyView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom, 10)
                        
                        Text("Last Updated: November 19, 2025")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .padding(.bottom, 20)
                        
                        // Introduction
                        sectionHeader("Introduction")
                        bodyText("""
                        BeatMap ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.
                        
                        By using BeatMap, you agree to the collection and use of information in accordance with this policy.
                        """)
                        
                        // Information We Collect
                        sectionHeader("Information We Collect")
                        
                        subSectionHeader("1. Personal Information")
                        bodyText("""
                        • Spotify Account Information: When you connect your Spotify account, we access your Spotify user ID, email, display name, and listening history
                        • Location Data: We collect precise location data when you create journal entries to associate songs with places
                        • Journal Entries: Your written reflections, mood ratings, and activity context
                        """)
                        
                        subSectionHeader("2. Music Data")
                        bodyText("""
                        • Songs you've listened to and journaled about
                        • Audio features from Spotify (tempo, energy, danceability, etc.)
                        • Artist and genre information
                        • Album artwork URLs
                        """)
                        
                        subSectionHeader("3. Usage Data")
                        bodyText("""
                        • App interactions and features used
                        • Device information (model, OS version)
                        • Crash reports and error logs
                        """)
                        
                        // How We Use Your Information
                        sectionHeader("How We Use Your Information")
                        bodyText("""
                        We use your information to:
                        
                        • Provide and maintain the BeatMap service
                        • Create and display your music journal entries
                        • Show your entries on an interactive map
                        • Generate insights about your listening patterns
                        • Improve app functionality and user experience
                        • Communicate with you about updates or issues
                        • Provide customer support
                        """)
                        
                        // Data Storage
                        sectionHeader("Data Storage and Security")
                        bodyText("""
                        • All journal entries are stored locally on your device using Core Data
                        • Location data is stored encrypted on your device
                        • Spotify access tokens are stored securely in iOS Keychain
                        • We do not transmit your journal entries or location data to external servers
                        • Your data remains on your device and under your control
                        """)
                        
                        // Third-Party Services
                        sectionHeader("Third-Party Services")
                        
                        subSectionHeader("Spotify")
                        bodyText("""
                        BeatMap integrates with Spotify to access your music data. When you connect your Spotify account:
                        
                        • We use Spotify's OAuth 2.0 authentication
                        • We access your recently played tracks and currently playing song
                        • We retrieve audio features and artist information
                        • Your use of Spotify is governed by Spotify's Privacy Policy and Terms of Service
                        
                        You can revoke BeatMap's access to your Spotify account at any time through your Spotify account settings.
                        """)
                        
                        subSectionHeader("ShazamKit")
                        bodyText("""
                        We use Apple's ShazamKit framework for song identification. Audio captured during song recognition:
                        
                        • Is processed locally on your device
                        • Is not stored or transmitted to our servers
                        • May be sent to Apple's Shazam service for identification
                        • Is governed by Apple's Privacy Policy
                        """)
                        
                        // Location Data
                        sectionHeader("Location Data")
                        bodyText("""
                        BeatMap collects precise location data to:
                        
                        • Tag journal entries with the place where you heard a song
                        • Display entries on an interactive map
                        • Provide location-based insights
                        
                        Location data is:
                        • Collected only when you create a journal entry
                        • Stored locally on your device
                        • Never shared with third parties
                        • Can be manually edited or changed
                        
                        You can deny location permissions, but this will limit map functionality.
                        """)
                        
                        // Data Retention
                        sectionHeader("Data Retention")
                        bodyText("""
                        • Journal entries are retained indefinitely on your device until you delete them
                        • You can delete individual entries or all entries at any time
                        • When you delete entries, they are permanently removed from your device
                        • Spotify access tokens remain until you log out or revoke access
                        """)
                        
                        // Your Rights
                        sectionHeader("Your Rights")
                        bodyText("""
                        You have the right to:
                        
                        • Access all data stored by BeatMap on your device
                        • Delete individual entries or all entries
                        • Revoke Spotify access at any time
                        • Disable location services
                        • Export your data (planned feature)
                        • Request information about how your data is used
                        """)
                        
                        // Children's Privacy
                        sectionHeader("Children's Privacy")
                        bodyText("""
                        BeatMap is not intended for use by children under 13 years of age. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us immediately.
                        """)
                        
                        // Changes to This Policy
                        sectionHeader("Changes to This Privacy Policy")
                        bodyText("""
                        We may update our Privacy Policy from time to time. We will notify you of any changes by:
                        
                        • Posting the new Privacy Policy in the app
                        • Updating the "Last Updated" date
                        • Sending an in-app notification for material changes
                        
                        You are advised to review this Privacy Policy periodically for any changes.
                        """)
                        
                        // Contact
                        sectionHeader("Contact Us")
                        bodyText("""
                        If you have questions about this Privacy Policy, please contact us:
                        
                        Email: beatmaphelp@gmail.com
                        """)
                        
                        Divider()
                            .padding(.vertical)
                        
                        Text("By using BeatMap, you acknowledge that you have read and understood this Privacy Policy.")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .italic()
                            .padding(.bottom, 40)
                    }
                    .padding()
                }
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.title2)
            .fontWeight(.bold)
            .padding(.top, 10)
    }
    
    private func subSectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .fontWeight(.semibold)
            .padding(.top, 8)
    }
    
    private func bodyText(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .lineSpacing(4)
    }
}

#Preview {
    PreviewContainer {
        PrivacyPolicyView()
    }
}
