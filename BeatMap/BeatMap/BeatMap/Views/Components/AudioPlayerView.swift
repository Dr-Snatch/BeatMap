// MARK: - File Header
//
// AudioPlayerView.swift
// BeatMap
//
// Version: 2.0.0 (Audio Snippets + Core Data)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI
import AVFoundation
import Combine

/// Audio player component for playing back captured moment snippets.
/// Shows waveform visualization and playback controls.
struct AudioPlayerView: View {
    
    let audioFileName: String
    
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var player = AudioPlayer()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(themeManager.currentTheme.accentColor)
                Text("Captured Moment")
                    .font(.headline)
                Spacer()
                Text(formatDuration(player.currentTime))
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            // Waveform visualization
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeManager.currentTheme.secondaryBackgroundColor)
                    .frame(height: 60)
                
                // Animated waveform bars
                HStack(spacing: 2) {
                    ForEach(0..<50, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(player.isPlaying ? themeManager.currentTheme.accentColor : themeManager.currentTheme.secondaryTextColor.opacity(0.3))
                            .frame(width: 3, height: CGFloat.random(in: 10...50))
                            .animation(
                                player.isPlaying ? Animation.easeInOut(duration: 0.3).repeatForever() : .default,
                                value: player.isPlaying
                            )
                    }
                }
                .padding(.horizontal, 8)
                
                // Progress overlay
                GeometryReader { geometry in
                    Rectangle()
                        .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                        .frame(width: geometry.size.width * CGFloat(player.progress))
                }
            }
            .frame(height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Playback controls
            HStack {
                // Play/Pause button
                Button(action: {
                    if player.isPlaying {
                        player.pause()
                    } else {
                        player.play(audioFileName: audioFileName)
                    }
                }) {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
                
                Spacer()
                
                // Duration
                Text("\(formatDuration(player.duration))")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
        .cornerRadius(12)
        .onDisappear {
            player.stop()
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Audio Player

/// Manages AVAudioPlayer for audio snippet playback
class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var progress: Double = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    func play(audioFileName: String) {
        let url = AudioStorageManager.shared.audioURL(for: audioFileName)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ Audio file not found: \(audioFileName)")
            return
        }
        
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            duration = audioPlayer?.duration ?? 0
            isPlaying = true
            
            // Update progress
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let player = self.audioPlayer else { return }
                self.currentTime = player.currentTime
                self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
            }
            
            print("▶️ Playing audio: \(audioFileName)")
        } catch {
            print("❌ Playback failed: \(error)")
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        timer?.invalidate()
        print("⏸️ Audio paused")
    }
    
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        currentTime = 0
        progress = 0
        timer?.invalidate()
        
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentTime = 0
            self.progress = 0
            self.timer?.invalidate()
        }
    }
}

#Preview {
    PreviewContainer {
        AudioPlayerView(audioFileName: "test.m4a")
            .padding()
    }
}
