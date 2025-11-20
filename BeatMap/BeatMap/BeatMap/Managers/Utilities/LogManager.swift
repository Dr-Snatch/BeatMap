// MARK: - File Header
//
// LogManager.swift
// BeatMap
//
// Version: 1.0.0
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import Foundation
import UIKit

/// Manages debug logging and log export for BeatMap.
/// Simple singleton that captures events for troubleshooting.
class LogManager {
    
    static let shared = LogManager()
    
    private(set) var logs: [LogEntry] = []
    private let maxLogs = 500
    
    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let level: LogLevel
    }
    
    enum LogLevel: String {
        case info = "ℹ️"
        case success = "✅"
        case warning = "⚠️"
        case error = "❌"
        case debug = "🔵"
    }
    
    private init() {}
    
    /// Log a message with specified level
    func log(_ message: String, level: LogLevel = .info) {
        let entry = LogEntry(timestamp: Date.now, message: message, level: level)
        
        logs.append(entry)
        
        if logs.count > maxLogs {
            logs.removeFirst(logs.count - maxLogs)
        }
        
        print("\(level.rawValue) \(message)")
    }
    
    /// Generate formatted log report
    func generateLogReport() -> String {
        let deviceInfo = """
        BeatMap Debug Report
        ====================
        
        App Version: 1.1.0
        Device: \(UIDevice.current.name)
        iOS Version: \(UIDevice.current.systemVersion)
        Model: \(UIDevice.current.model)
        Generated: \(Date.now.formatted(date: .complete, time: .complete))
        
        ====================
        Recent Logs (\(logs.count)):
        ====================
        
        """
        
        let logMessages = logs.suffix(100).map { entry in
            let timestamp = entry.timestamp.formatted(date: .omitted, time: .standard)
            return "\(timestamp) \(entry.level.rawValue) \(entry.message)"
        }.joined(separator: "\n")
        
        return deviceInfo + logMessages
    }
    
    /// Clear all logs
    func clearLogs() {
        logs.removeAll()
        print("🗑️ Logs cleared")
    }
}
