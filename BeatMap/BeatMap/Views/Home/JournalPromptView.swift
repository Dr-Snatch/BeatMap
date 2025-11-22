// MARK: - File Header
//
// JournalPromptView.swift
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

/// A card displayed on the home screen showing an inspiring journal prompt.
/// Encourages users to create new BeatMap entries with creative reflection starters.
struct JournalPromptView: View {
    
    let prompt: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading) {
            // Card header
            Text("Feeling Inspired?")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                .padding(.bottom, 5)

            // Prompt content
            HStack(spacing: 15) {
                Image(systemName: "pencil.and.scribble")
                    .font(.title2)
                    .foregroundStyle(themeManager.currentTheme.accentColor)
                
                Text(prompt)
                    .font(.body)
                    .foregroundStyle(themeManager.currentTheme.primaryTextColor)
                
                Spacer()
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    PreviewContainer {
        JournalPromptView(prompt: "What song reminds you of summer?")
            .padding()
    }
}
