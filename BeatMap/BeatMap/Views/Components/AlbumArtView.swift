// MARK: - File Header
//
// AlbumArtView.swift
// BeatMap
//
// Version: 1.1.0 (Cached & Optimized)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI

/// Reusable view for displaying album artwork in BeatMap.
/// Now uses ImageCacheManager for lightning-fast loading and reduced network usage.
struct AlbumArtView: View {
    
    // MARK: - Properties
    
    let song: Song
    var size: CGFloat = 50
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    // Computed size that adapts to device
    private var adaptiveSize: CGFloat {
        AdaptiveSize.scale(size, for: horizontalSizeClass)
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let image = loadedImage {
                // Display cached/loaded image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: adaptiveSize, height: adaptiveSize)
                    .cornerRadius(adaptiveSize / 10)
                    .clipped()
                
            } else if let urlString = song.albumArtURL {
                // Loading state for remote image
                ZStack {
                    themeManager.currentTheme.secondaryBackgroundColor
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: adaptiveSize * 0.4))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.5))
                    }
                }
                .frame(width: adaptiveSize, height: adaptiveSize)
                .cornerRadius(adaptiveSize / 10)
                .task {
                    await loadImageFromCache(urlString)
                }
                
            } else {
                // Display SF Symbol placeholder
                ZStack {
                    themeManager.currentTheme.secondaryBackgroundColor
                    Image(systemName: song.albumArtSymbol ?? "music.note")
                        .font(.system(size: adaptiveSize * 0.5))
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                .frame(width: adaptiveSize, height: adaptiveSize)
                .cornerRadius(adaptiveSize / 10)
            }
        }
    }
    
    // MARK: - Image Loading
    
    private func loadImageFromCache(_ urlString: String) async {
        isLoading = true
        loadedImage = await ImageCacheManager.shared.loadImage(from: urlString)
        isLoading = false
    }
}

#Preview {
    PreviewContainer {
        HStack(spacing: 20) {
            // Remote URL example
            AlbumArtView(
                song: Song(
                    id: "test",
                    title: "Test",
                    artist: "Artist",
                    albumArtURL: "https://i.scdn.co/image/ab67616d00001e024ae1c4c5c45aabe565499163"
                ),
                size: 100
            )
            
            // SF Symbol example
            AlbumArtView(
                song: Song(id: "1", title: "Sample", artist: "Artist", albumArtSymbol: "music.mic"),
                size: 100
            )
            
            // Fallback example
            AlbumArtView(
                song: Song(id: "2", title: "No Art", artist: "Artist"),
                size: 100
            )
        }
        .padding()
    }
}
