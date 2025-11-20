// MARK: - File Header
//
// CustomSliderView.swift
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

/// Reusable slider component with labeled icons for subjective metrics.
/// Used throughout BeatMap for nostalgia, energy, and mood ratings.
struct CustomSliderView: View {
    
    // MARK: - Properties
    
    let label: String
    let leftIcon: String
    let rightIcon: String
    
    @Binding var value: Double
    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading) {
            // Slider label
            Text(label)
                .font(.subheadline)
                .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
            
            // Slider with icons
            HStack(spacing: 10) {
                Image(systemName: leftIcon)
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                
                Slider(value: $value, in: 0...100)
                    .tint(themeManager.currentTheme.accentColor)
                
                Image(systemName: rightIcon)
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(8)
    }
}

#Preview {
    PreviewContainer {
        @State var previewValue: Double = 75
        
        CustomSliderView(
            label: "Nostalgia",
            leftIcon: "hourglass",
            rightIcon: "sparkles",
            value: $previewValue
        )
        .padding()
    }
}
