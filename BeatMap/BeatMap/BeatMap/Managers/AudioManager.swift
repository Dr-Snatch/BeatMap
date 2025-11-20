// MARK: - File Header
//
// AudioManager.swift
// BeatMap
//
// Version: 2.0.0 (Consolidated Audio Management)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import Foundation
import AVFoundation
import Combine

// MARK: - Audio Storage Manager

/// Manages storage and retrieval of audio snippet files.
/// Handles file operations in the app's Documents directory.
class AudioStorageManager {
    
    // MARK: - Singleton
    
    static let shared = AudioStorageManager()
    
    // MARK: - Properties
    
    private let audioDirectory: URL
    
    // MARK: - Initialization
    
    private init() {
        // Create BeatMapAudio directory in Documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        audioDirectory = documentsPath.appendingPathComponent("BeatMapAudio", isDirectory: true)
        
        // Ensure directory exists
        if !FileManager.default.fileExists(atPath: audioDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
                print("✅ Audio directory created: \(audioDirectory.path)")
            } catch {
                print("❌ Failed to create audio directory: \(error)")
            }
        }
    }
    
    // MARK: - File Operations
    
    /// Generate a unique filename for a new audio snippet
    func generateFileName() -> String {
        let uuid = UUID().uuidString
        return "\(uuid).m4a"
    }
    
    /// Get the full URL for an audio file
    func audioURL(for fileName: String) -> URL {
        audioDirectory.appendingPathComponent(fileName)
    }
    
    /// Check if an audio file exists
    func audioExists(fileName: String) -> Bool {
        let url = audioURL(for: fileName)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    /// Save audio data to a file
    func saveAudio(data: Data, fileName: String) -> Bool {
        let url = audioURL(for: fileName)
        
        do {
            try data.write(to: url)
            print("✅ Audio saved: \(fileName) (\(data.count) bytes)")
            return true
        } catch {
            print("❌ Failed to save audio: \(error)")
            return false
        }
    }
    
    /// Load audio data from a file
    func loadAudio(fileName: String) -> Data? {
        let url = audioURL(for: fileName)
        
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            print("❌ Failed to load audio: \(error)")
            return nil
        }
    }
    
    /// Delete an audio file
    func deleteAudio(fileName: String) {
        let url = audioURL(for: fileName)
        
        do {
            try FileManager.default.removeItem(at: url)
            print("🗑️ Audio deleted: \(fileName)")
        } catch {
            print("❌ Failed to delete audio: \(error)")
        }
    }
    
    /// Delete all audio files
    func deleteAllAudio() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: audioDirectory, includingPropertiesForKeys: nil)
            
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            
            print("🗑️ All audio files deleted (\(files.count) files)")
        } catch {
            print("❌ Failed to delete all audio: \(error)")
        }
    }
    
    /// Get total storage size of all audio files
    func getTotalAudioSize() -> Int64 {
        var totalSize: Int64 = 0
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: audioDirectory, includingPropertiesForKeys: [.fileSizeKey])
            
            for file in files {
                let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(attributes.fileSize ?? 0)
            }
        } catch {
            print("❌ Failed to calculate audio size: \(error)")
        }
        
        return totalSize
    }
    
    /// Get formatted storage size string (e.g., "2.5 MB")
    func getFormattedAudioSize() -> String {
        let bytes = getTotalAudioSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    /// Get count of audio files
    func getAudioFileCount() -> Int {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: audioDirectory, includingPropertiesForKeys: nil)
            return files.count
        } catch {
            return 0
        }
    }
}

// MARK: - Audio Capture Manager

/// Manages audio recording for capturing 15-second moments.
/// Works alongside ShazamManager to record while identifying songs.
class AudioCaptureManager: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    @Published var isRecording = false
    @Published var recordingError: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var recordingTimer: Timer?
    private let maxRecordingDuration: TimeInterval = 15.0
    
    // MARK: - Public Methods
    
    /// Start recording audio (15 seconds max)
    @MainActor
    func startRecording() -> Bool {
        print("🎤 Starting audio capture...")
        
        // Configure audio session
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("❌ Audio session setup failed: \(error)")
            recordingError = "Could not access microphone"
            return false
        }
        #endif
        
        // Create temporary recording URL
        let fileName = AudioStorageManager.shared.generateFileName()
        recordingURL = AudioStorageManager.shared.audioURL(for: fileName)
        
        guard let recordingURL = recordingURL else {
            recordingError = "Could not create recording file"
            return false
        }
        
        // Configure recorder settings (M4A format, good quality, small size)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            
            // Start recording
            let success = audioRecorder?.record() ?? false
            
            if success {
                isRecording = true
                print("✅ Recording started: \(fileName)")
                
                // Auto-stop after 15 seconds
                recordingTimer = Timer.scheduledTimer(withTimeInterval: maxRecordingDuration, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        self?.stopRecording()
                    }
                }
                
                return true
            } else {
                recordingError = "Recording failed to start"
                return false
            }
        } catch {
            print("❌ Recorder initialization failed: \(error)")
            recordingError = error.localizedDescription
            return false
        }
    }
    
    /// Stop recording and return the audio file name
    @MainActor
    func stopRecording() -> String? {
        print("⏹️ Stopping audio capture...")
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        audioRecorder?.stop()
        isRecording = false
        
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("⚠️ Failed to deactivate audio session: \(error)")
        }
        #endif
        
        // Return the filename (not full path)
        if let url = recordingURL {
            let fileName = url.lastPathComponent
            print("✅ Recording saved: \(fileName)")
            return fileName
        }
        
        return nil
    }
    
    /// Cancel recording and delete the file
    @MainActor
    func cancelRecording() {
        print("❌ Cancelling audio capture...")
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        audioRecorder?.stop()
        isRecording = false
        
        // Delete the recording file
        if let url = recordingURL {
            do {
                try FileManager.default.removeItem(at: url)
                print("🗑️ Recording cancelled and deleted")
            } catch {
                print("⚠️ Failed to delete cancelled recording: \(error)")
            }
        }
        
        recordingURL = nil
        
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("⚠️ Failed to deactivate audio session: \(error)")
        }
        #endif
    }
    
    /// Get the current recording duration
    func getRecordingDuration() -> TimeInterval {
        audioRecorder?.currentTime ?? 0
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioCaptureManager: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("✅ Recording finished successfully")
        } else {
            print("⚠️ Recording finished with errors")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("❌ Recording encode error: \(error)")
            Task { @MainActor in
                self.recordingError = error.localizedDescription
            }
        }
    }
}
