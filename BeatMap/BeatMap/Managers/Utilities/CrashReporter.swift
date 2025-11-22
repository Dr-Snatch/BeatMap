// MARK: - File Header
//
// CrashReporter.swift
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

/// Captures and manages crash reports and unhandled exceptions in BeatMap.
/// Automatically logs crashes and provides detailed reports for debugging.
class CrashReporter {
    
    static let shared = CrashReporter()
    
    private let crashReportsKey = "beatmap.crashReports"
    private let maxCrashReports = 10
    
    struct CrashReport: Codable, Identifiable {
        let id: UUID
        let timestamp: Date
        let errorDescription: String
        let errorType: String
        let stackTrace: String
        let appVersion: String
        let deviceInfo: DeviceInfo
        let logs: [String]
        
        var dateString: String {
            timestamp.formatted(date: .abbreviated, time: .standard)
        }
    }
    
    struct DeviceInfo: Codable {
        let device: String
        let osVersion: String
        let model: String
        let appVersion: String
    }
    
    private(set) var crashReports: [CrashReport] = []
    
    private init() {
        loadCrashReports()
        setupCrashHandlers()
    }
    
    // MARK: - Setup
    
    private func setupCrashHandlers() {
        NSSetUncaughtExceptionHandler { exception in
            let errorDescription = "\(exception.name.rawValue): \(exception.reason ?? "Unknown reason")"
            let stackTrace = exception.callStackSymbols.joined(separator: "\n")
            
            print("💥 UNCAUGHT EXCEPTION: \(errorDescription)")
            LogManager.shared.log("CRASH: \(errorDescription)", level: .error)
            
            CrashReporter.shared.createCrashReport(
                errorDescription: errorDescription,
                errorType: "NSException",
                stackTrace: stackTrace
            )
        }
        
        signal(SIGSEGV) { sig in
            let errorDescription = "Fatal signal received: SIGSEGV (\(sig))"
            let stackTrace = Thread.callStackSymbols.joined(separator: "\n")
            
            print("💥 FATAL SIGNAL: \(errorDescription)")
            
            CrashReporter.shared.createCrashReport(
                errorDescription: errorDescription,
                errorType: "Signal",
                stackTrace: stackTrace
            )
            
            signal(sig, SIG_DFL)
            raise(sig)
        }
        
        signal(SIGBUS) { sig in
            let errorDescription = "Fatal signal received: SIGBUS (\(sig))"
            let stackTrace = Thread.callStackSymbols.joined(separator: "\n")
            
            print("💥 FATAL SIGNAL: \(errorDescription)")
            
            CrashReporter.shared.createCrashReport(
                errorDescription: errorDescription,
                errorType: "Signal",
                stackTrace: stackTrace
            )
            
            signal(sig, SIG_DFL)
            raise(sig)
        }
        
        signal(SIGILL) { sig in
            let errorDescription = "Fatal signal received: SIGILL (\(sig))"
            let stackTrace = Thread.callStackSymbols.joined(separator: "\n")
            
            print("💥 FATAL SIGNAL: \(errorDescription)")
            
            CrashReporter.shared.createCrashReport(
                errorDescription: errorDescription,
                errorType: "Signal",
                stackTrace: stackTrace
            )
            
            signal(sig, SIG_DFL)
            raise(sig)
        }
        
        signal(SIGABRT) { sig in
            let errorDescription = "Fatal signal received: SIGABRT (\(sig))"
            let stackTrace = Thread.callStackSymbols.joined(separator: "\n")
            
            print("💥 FATAL SIGNAL: \(errorDescription)")
            
            CrashReporter.shared.createCrashReport(
                errorDescription: errorDescription,
                errorType: "Signal",
                stackTrace: stackTrace
            )
            
            signal(sig, SIG_DFL)
            raise(sig)
        }
        
        print("✅ Crash handlers initialized")
        LogManager.shared.log("Crash reporting initialized", level: .success)
    }
    
    // MARK: - Manual Error Logging
    
    func logCriticalError(_ error: Error, context: String = "") {
        let errorDescription = "\(context.isEmpty ? "" : "\(context): ")\(error.localizedDescription)"
        let stackTrace = Thread.callStackSymbols.joined(separator: "\n")
        
        print("⚠️ CRITICAL ERROR: \(errorDescription)")
        LogManager.shared.log("CRITICAL ERROR: \(errorDescription)", level: .error)
        
        createCrashReport(
            errorDescription: errorDescription,
            errorType: "CriticalError",
            stackTrace: stackTrace
        )
    }
    
    func logCustomError(description: String, type: String, additionalInfo: String = "") {
        let errorDescription = description + (additionalInfo.isEmpty ? "" : "\n\nAdditional Info:\n\(additionalInfo)")
        let stackTrace = Thread.callStackSymbols.joined(separator: "\n")
        
        print("🔴 CUSTOM ERROR: \(description)")
        LogManager.shared.log("ERROR: \(description)", level: .error)
        
        createCrashReport(
            errorDescription: errorDescription,
            errorType: type,
            stackTrace: stackTrace
        )
    }
    
    // MARK: - Report Creation
    
    fileprivate func createCrashReport(errorDescription: String, errorType: String, stackTrace: String) {
        let deviceInfo = DeviceInfo(
            device: UIDevice.current.name,
            osVersion: UIDevice.current.systemVersion,
            model: UIDevice.current.model,
            appVersion: "1.1.0"
        )
        
        let recentLogs = LogManager.shared.logs.suffix(20).map { entry in
            let timestamp = entry.timestamp.formatted(date: .omitted, time: .standard)
            return "\(timestamp) \(entry.level.rawValue) \(entry.message)"
        }
        
        let report = CrashReport(
            id: UUID(),
            timestamp: Date.now,
            errorDescription: errorDescription,
            errorType: errorType,
            stackTrace: stackTrace,
            appVersion: "1.1.0",
            deviceInfo: deviceInfo,
            logs: recentLogs
        )
        
        saveCrashReport(report)
    }
    
    // MARK: - Persistence
    
    private func saveCrashReport(_ report: CrashReport) {
        crashReports.insert(report, at: 0)
        
        if crashReports.count > maxCrashReports {
            crashReports = Array(crashReports.prefix(maxCrashReports))
        }
        
        if let encoded = try? JSONEncoder().encode(crashReports) {
            UserDefaults.standard.set(encoded, forKey: crashReportsKey)
            print("💾 Crash report saved (\(crashReports.count) total)")
        }
    }
    
    private func loadCrashReports() {
        if let data = UserDefaults.standard.data(forKey: crashReportsKey),
           let decoded = try? JSONDecoder().decode([CrashReport].self, from: data) {
            crashReports = decoded
            print("📋 Loaded \(crashReports.count) crash reports")
        }
    }
    
    func clearAllReports() {
        crashReports.removeAll()
        UserDefaults.standard.removeObject(forKey: crashReportsKey)
        print("🗑️ All crash reports cleared")
        LogManager.shared.log("Crash reports cleared by user", level: .info)
    }
    
    func deleteReport(_ reportId: UUID) {
        crashReports.removeAll { $0.id == reportId }
        if let encoded = try? JSONEncoder().encode(crashReports) {
            UserDefaults.standard.set(encoded, forKey: crashReportsKey)
        }
    }
    
    // MARK: - Report Generation
    
    func generateCrashReportText(_ report: CrashReport) -> String {
        return """
        ═══════════════════════════════════════
        BeatMap Crash Report
        ═══════════════════════════════════════
        
        App Version: \(report.appVersion)
        Crash Date: \(report.dateString)
        Report ID: \(report.id.uuidString)
        
        ═══════════════════════════════════════
        Device Information
        ═══════════════════════════════════════
        
        Device: \(report.deviceInfo.device)
        Model: \(report.deviceInfo.model)
        iOS Version: \(report.deviceInfo.osVersion)
        
        ═══════════════════════════════════════
        Error Details
        ═══════════════════════════════════════
        
        Type: \(report.errorType)
        Description:
        \(report.errorDescription)
        
        ═══════════════════════════════════════
        Stack Trace
        ═══════════════════════════════════════
        
        \(report.stackTrace)
        
        ═══════════════════════════════════════
        Recent Log Entries (Last 20)
        ═══════════════════════════════════════
        
        \(report.logs.joined(separator: "\n"))
        
        ═══════════════════════════════════════
        End of Report
        ═══════════════════════════════════════
        """
    }
    
    func generateSummaryReport() -> String {
        guard !crashReports.isEmpty else {
            return "No crash reports available."
        }
        
        let summary = crashReports.enumerated().map { index, report in
            """
            
            Crash #\(index + 1)
            Date: \(report.dateString)
            Type: \(report.errorType)
            Error: \(report.errorDescription.split(separator: "\n").first ?? "Unknown")
            """
        }.joined(separator: "\n")
        
        return """
        BeatMap Crash Summary
        Total Crashes: \(crashReports.count)
        \(summary)
        """
    }
}
