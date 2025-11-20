// MARK: - File Header
//
// TermsOfServiceView.swift
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

/// Displays BeatMap's Terms of Service
/// Defines the legal agreement between BeatMap and its users
struct TermsOfServiceView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        Text("Terms of Service")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom, 10)
                        
                        Text("Last Updated: November 19, 2025")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .padding(.bottom, 20)
                        
                        // Agreement
                        sectionHeader("Agreement to Terms")
                        bodyText("""
                        By accessing or using BeatMap, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree to these terms, please do not use BeatMap.
                        """)
                        
                        // License
                        sectionHeader("1. License and Usage")
                        
                        subSectionHeader("License Grant")
                        bodyText("""
                        Subject to your compliance with these Terms, we grant you a limited, non-exclusive, non-transferable, revocable license to:
                        
                        • Download and install BeatMap on your personal device
                        • Use BeatMap for personal, non-commercial purposes
                        • Create and maintain your music journal entries
                        """)
                        
                        subSectionHeader("License Restrictions")
                        bodyText("""
                        You agree NOT to:
                        
                        • Modify, reverse engineer, or decompile the app
                        • Remove any copyright or proprietary notices
                        • Use the app for any illegal purposes
                        • Attempt to gain unauthorized access to our systems
                        • Share your Spotify credentials with others
                        • Use automated systems to access the app
                        • Violate any applicable laws or regulations
                        """)
                        
                        // User Accounts
                        sectionHeader("2. User Accounts and Spotify Integration")
                        bodyText("""
                        • You must have a valid Spotify account to use BeatMap
                        • You are responsible for maintaining the security of your Spotify account
                        • You must comply with Spotify's Terms of Service
                        • You can disconnect your Spotify account at any time
                        • We are not responsible for issues with your Spotify account
                        """)
                        
                        // User Content
                        sectionHeader("3. Your Content")
                        
                        subSectionHeader("Ownership")
                        bodyText("""
                        • You retain all rights to your journal entries and content
                        • You are solely responsible for the content you create
                        • Your content is stored locally on your device
                        • We do not claim ownership of your journal entries
                        """)
                        
                        subSectionHeader("Prohibited Content")
                        bodyText("""
                        You agree not to create journal entries that contain:
                        
                        • Illegal, harmful, or offensive content
                        • Hate speech or discriminatory content
                        • Content that violates others' rights
                        • Spam or commercial solicitations
                        • Malicious code or viruses
                        """)
                        
                        // Intellectual Property
                        sectionHeader("4. Intellectual Property")
                        bodyText("""
                        BeatMap and its original content, features, and functionality are owned by A. Wheildon and are protected by international copyright, trademark, and other intellectual property laws.
                        
                        • BeatMap name and logo are trademarks
                        • App design and interface are protected by copyright
                        • You may not use our trademarks without permission
                        
                        Third-party content (Spotify album artwork, song data, etc.) remains the property of their respective owners.
                        """)
                        
                        // Location Services
                        sectionHeader("5. Location Services")
                        bodyText("""
                        • BeatMap requests access to your device location
                        • Location data is used only to tag journal entries
                        • You can deny location access, but map features will be limited
                        • Location data is stored locally on your device
                        • You are responsible for the accuracy of location data
                        """)
                        
                        // Third-Party Services
                        sectionHeader("6. Third-Party Services")
                        bodyText("""
                        BeatMap integrates with third-party services:
                        
                        • Spotify: For music data and authentication
                        • Apple ShazamKit: For song identification
                        • Apple Maps: For location display
                        
                        Your use of these services is subject to their respective terms and conditions. We are not responsible for third-party services or their availability.
                        """)
                        
                        // Disclaimers
                        sectionHeader("7. Disclaimers")
                        bodyText("""
                        BeatMap is provided "AS IS" and "AS AVAILABLE" without warranties of any kind, either express or implied, including but not limited to:
                        
                        • Warranties of merchantability or fitness for a particular purpose
                        • That the service will be uninterrupted or error-free
                        • That defects will be corrected
                        • That the app is free of viruses or harmful components
                        • The accuracy of location data
                        • The availability of Spotify integration
                        
                        We make no guarantees about the accuracy, reliability, or completeness of any content or features.
                        """)
                        
                        // Limitation of Liability
                        sectionHeader("8. Limitation of Liability")
                        bodyText("""
                        To the maximum extent permitted by law, A. Wheildon shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to:
                        
                        • Loss of data or journal entries
                        • Loss of profits or revenue
                        • Loss of use or access to the app
                        • Device damage or malfunction
                        • Emotional distress
                        
                        Our total liability shall not exceed the amount you paid for BeatMap (if any).
                        """)
                        
                        // Data Loss
                        sectionHeader("9. Data Backup and Loss")
                        bodyText("""
                        • You are responsible for backing up your journal entries
                        • We are not liable for any data loss
                        • Device issues, app updates, or deletions may result in data loss
                        • We recommend regularly exporting your data (when available)
                        • No warranty is provided regarding data preservation
                        """)
                        
                        // Termination
                        sectionHeader("10. Termination")
                        bodyText("""
                        We reserve the right to:
                        
                        • Suspend or terminate your access to BeatMap
                        • Remove the app from distribution
                        • Discontinue features or the entire service
                        
                        Without notice or liability if you:
                        
                        • Violate these Terms of Service
                        • Engage in fraudulent or illegal activity
                        • Abuse or misuse the service
                        
                        You may terminate your use of BeatMap at any time by deleting the app from your device.
                        """)
                        
                        // Changes to Terms
                        sectionHeader("11. Changes to Terms")
                        bodyText("""
                        We reserve the right to modify these Terms at any time. We will notify users of material changes by:
                        
                        • Posting updated Terms in the app
                        • Updating the "Last Updated" date
                        • Sending in-app notifications
                        
                        Your continued use of BeatMap after changes constitutes acceptance of the new Terms.
                        """)
                        
                        // Governing Law
                        sectionHeader("12. Governing Law")
                        bodyText("""
                        These Terms shall be governed by and construed in accordance with the laws of England and Wales, without regard to its conflict of law provisions.
                        
                        Any disputes arising from these Terms or your use of BeatMap shall be subject to the exclusive jurisdiction of the courts of England and Wales.
                        """)
                        
                        // Severability
                        sectionHeader("13. Severability")
                        bodyText("""
                        If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary so that the remaining provisions remain in full force and effect.
                        """)
                        
                        // Entire Agreement
                        sectionHeader("14. Entire Agreement")
                        bodyText("""
                        These Terms, together with our Privacy Policy, constitute the entire agreement between you and BeatMap regarding your use of the app and supersede any prior agreements.
                        """)
                        
                        // Contact
                        sectionHeader("15. Contact Information")
                        bodyText("""
                        For questions about these Terms of Service, please contact us:
                        
                        Email: beatmaphelp@gmail.com
                        """)
                        
                        Divider()
                            .padding(.vertical)
                        
                        Text("By using BeatMap, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .italic()
                            .padding(.bottom, 40)
                    }
                    .padding()
                }
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            }
            .navigationTitle("Terms of Service")
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
        TermsOfServiceView()
    }
}
