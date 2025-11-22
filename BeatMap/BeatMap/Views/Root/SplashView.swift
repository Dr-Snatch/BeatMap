// MARK: - File Header
//
// SplashView.swift
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

struct SplashView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background - use your theme color
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App icon or logo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .opacity(isAnimating ? 0.8 : 1.0)
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundColor(.white)
                }
                .shadow(color: .purple.opacity(0.5), radius: 20)
                
                // App name
                VStack(spacing: 8) {
                    Text("BeatMap")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Music. Moments. Mapped.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Loading indicator
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                    .padding(.top, 20)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashView()
}
