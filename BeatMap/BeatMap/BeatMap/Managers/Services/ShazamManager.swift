//
//  ShazamManager.swift
//  BeatMap
//
//  Created by Arthur  on 18/11/2025.
//

import Foundation
import ShazamKit
import AVKit
import Combine

class ShazamManager: NSObject, ObservableObject, SHSessionDelegate {

    @Published var shazamState: ShazamState = .idle
    @Published var identifiedSong: Song?

    private let session = SHSession()
    private let engine = AVAudioEngine()

    enum ShazamState: Equatable {
        case idle
        case listening
        case match
        case noMatch
        case error(String)
    }

    override init() {
        super.init()
        session.delegate = self
        print("✅ ShazamManager initialized")
    }

    @MainActor
    func startListening() {
        print("▶️ Starting Shazam listening...")
        
        guard !engine.isRunning else {
            print("⚠️ Audio engine already running")
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        audioSession.requestRecordPermission { granted in
            Task { @MainActor in
                if granted {
                    print("✅ Microphone permission granted")
                    self.startAudioEngine()
                } else {
                    print("❌ Microphone permission denied")
                    self.shazamState = .error("Microphone access is required to identify songs.")
                }
            }
        }
    }

    @MainActor
    private func startAudioEngine() {
        print("⚙️ Starting audio engine...")
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record)
            try audioSession.setActive(true)

            let inputNode = self.engine.inputNode
            
            guard inputNode.inputFormat(forBus: 0).channelCount > 0 else {
                print("❌ No audio input available")
                self.shazamState = .error("No audio input detected. Please check microphone.")
                return
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            print("🎧 Audio format: \(recordingFormat)")

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, time in
                self.session.matchStreamingBuffer(buffer, at: time)
            }

            self.engine.prepare()
            try self.engine.start()
            self.shazamState = .listening
            print("🎤 Shazam is now listening...")

        } catch {
            print("❌ Audio engine failed to start: \(error.localizedDescription)")
            self.shazamState = .error("Could not start audio engine: \(error.localizedDescription)")
        }
    }

    @MainActor
    func stopListening() {
        print("⏹️ Stopping Shazam...")
        
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
            
            do {
                try AVAudioSession.sharedInstance().setActive(false)
            } catch {
                print("⚠️ Failed to deactivate audio session: \(error.localizedDescription)")
            }
            
            if shazamState == .listening {
                shazamState = .idle
            }
            print("🛑 Audio engine stopped")
        }
    }
    
    func session(_ session: SHSession, didFind match: SHMatch) {
        guard let mediaItem = match.mediaItems.first else {
            print("⚠️ Match found but no media items")
            return
        }
        
        Task { @MainActor in
            print("✅ Song identified: \(mediaItem.title ?? "Unknown") by \(mediaItem.artist ?? "Unknown")")
            
            self.identifiedSong = Song(
                id: mediaItem.shazamID ?? UUID().uuidString,
                title: mediaItem.title ?? "Unknown Title",
                artist: mediaItem.artist ?? "Unknown Artist",
                albumArtSymbol: "shazam.logo.fill"
            )
            
            self.shazamState = .match
            self.stopListening()
        }
    }
    
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ Shazam error: \(error.localizedDescription)")
                self.shazamState = .error("Could not identify song: \(error.localizedDescription)")
            } else {
                print("❌ No match found")
                self.shazamState = .noMatch
            }
            self.stopListening()
        }
    }
}
