// MARK: - File Header
//
// InsightsView.swift
// BeatMap
//
// Version: 3.1.0 (Smart Loading & Performance Optimized)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI
import Charts

/// Comprehensive analytics dashboard with smart loading and caching.
/// Optimized for instant response with progressive data loading.
struct InsightsView: View {
    
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedTimeRange: TimeRange = .all
    @State private var selectedInsightCategory: InsightCategory = .recommendations
    
    // Smart loading states
    @State private var isInitialLoad = true
    @State private var cachedInsights: CachedInsights?
    @State private var isCalculating = false
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        case year = "Year"
        case all = "All Time"
        
        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            case .all: return nil
            }
        }
    }
    
    enum InsightCategory: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case recommendations = "For You"
        case temporal = "Time Patterns"
        case musical = "Musical DNA"
        case location = "Places"
        case mood = "Mood Science"
        case social = "Social"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .recommendations: return "sparkles"
            case .temporal: return "clock.fill"
            case .musical: return "waveform"
            case .location: return "map.fill"
            case .mood: return "brain.head.profile"
            case .social: return "person.3.fill"
            }
        }
    }
    
    // MARK: - Cached Insights Model
    
    struct CachedInsights {
        let timeRange: TimeRange
        let entryCount: Int
        
        // Overview
        let uniqueSongs: Int
        let uniqueArtists: Int
        let averageMood: Double
        let currentStreak: Int?
        let mostActiveHour: Int?
        
        // Temporal
        let hourCounts: [Int: Int]
        let weekdayCounts: [Int: Int]
        let timeOfDayCounts: [String: Int]
        
        // Musical
        let audioFeatures: AudioFeatures
        let keyCounts: [Int: Int]
        let averageAcousticness: Double
        
        // Location
        let locationCounts: [(String, Int)]
        let totalDistance: Double
        let uniqueLocations: Int
        
        // Mood
        let activityMoods: [(String, Double)]
        let artistMoods: [(String, Double)]
        let majorMinorMoods: (major: Double, minor: Double)
        let averageNostalgia: Double
        
        // Social
        let aloneVsTogether: (alone: Int, together: Int)
        let companyCounts: [(String, Int)]
        let livePerformanceCount: Int
        
        struct AudioFeatures {
            let energy: Double
            let danceability: Double
            let valence: Double
            let acousticness: Double
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredEntries: [JournalEntry] {
        guard let days = selectedTimeRange.days else {
            return journalStore.entries
        }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date.now)!
        return journalStore.entries.filter { $0.date >= cutoffDate }
    }
    
    private var hasEntries: Bool {
        !filteredEntries.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea()
                
                if journalStore.entries.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        // Time range picker
                        timeRangePicker
                        
                        // Category tabs
                        categoryTabs
                        
                        ScrollView {
                            if isCalculating && cachedInsights == nil {
                                loadingSkeletonView
                            } else if hasEntries {
                                VStack(spacing: 25) {
                                    switch selectedInsightCategory {
                                    case .overview:
                                        overviewInsights
                                    case .recommendations:
                                        recommendationsInsights
                                    case .temporal:
                                        temporalInsights
                                    case .musical:
                                        musicalDNAInsights
                                    case .location:
                                        locationInsights
                                    case .mood:
                                        moodScienceInsights
                                    case .social:
                                        socialInsights
                                    }
                                }
                                .padding()
                            } else {
                                noDataForRangeView
                            }
                        }
                    }
                }
            }
            .navigationTitle("Insights")
            .task {
                if isInitialLoad {
                    await calculateInsights()
                    isInitialLoad = false
                }
            }
            .onChange(of: selectedTimeRange) {
                Task {
                    await calculateInsights()
                }
            }
            .onChange(of: journalStore.entries.count) {
                Task {
                    await calculateInsights()
                }
            }
        }
    }
    
    // MARK: - Loading Skeleton
    
    private var loadingSkeletonView: some View {
        VStack(spacing: 20) {
            // Skeleton cards
            ForEach(0..<4) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    Rectangle()
                        .fill(themeManager.currentTheme.secondaryBackgroundColor)
                        .frame(height: 20)
                        .frame(maxWidth: 150)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(themeManager.currentTheme.secondaryBackgroundColor)
                        .frame(height: 100)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .redacted(reason: .placeholder)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Smart Calculation
    
    @MainActor
    private func calculateInsights() async {
        isCalculating = true
        
        // Perform heavy calculations off main thread
        let insights = await Task.detached(priority: .userInitiated) {
            return computeInsights(for: filteredEntries, timeRange: selectedTimeRange)
        }.value
        
        cachedInsights = insights
        isCalculating = false
    }
    
    private func computeInsights(for entries: [JournalEntry], timeRange: TimeRange) -> CachedInsights {
        // Overview calculations
        let uniqueSongs = Set(entries.map { $0.song.id }).count
        let uniqueArtists = Set(entries.map { $0.song.artist }).count
        let averageMood = entries.isEmpty ? 0 : entries.reduce(0.0) { $0 + $1.moodValue } / Double(entries.count)
        let currentStreak = calculateStreakSync(entries: journalStore.entries)
        let mostActiveHour = Dictionary(grouping: entries, by: { Calendar.current.component(.hour, from: $0.date) })
            .max(by: { $0.value.count < $1.value.count })?.key
        
        // Temporal calculations
        let hourCounts = Dictionary(grouping: entries, by: { Calendar.current.component(.hour, from: $0.date) })
            .mapValues { $0.count }
        let weekdayCounts = Dictionary(grouping: entries, by: { Calendar.current.component(.weekday, from: $0.date) })
            .mapValues { $0.count }
        let timeOfDayCounts = Dictionary(grouping: entries, by: { getTimeOfDay(for: $0.date) })
            .mapValues { $0.count }
        
        // Musical calculations
        let avgEnergy = calculateAverageValue(entries, keyPath: \.spotifyEnergy)
        let avgDanceability = calculateAverageValue(entries, keyPath: \.danceability)
        let avgValence = calculateAverageValue(entries, keyPath: \.valence)
        let avgAcousticness = calculateAverageValue(entries, keyPath: \.acousticness)
        let audioFeatures = CachedInsights.AudioFeatures(
            energy: avgEnergy,
            danceability: avgDanceability,
            valence: avgValence,
            acousticness: avgAcousticness
        )
        let keyCounts = Dictionary(grouping: entries.compactMap { $0.key }, by: { $0 })
            .mapValues { $0.count }
        
        // Location calculations
        let locationCounts = Dictionary(grouping: entries, by: { $0.location })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        let totalDistance = calculateTotalDistanceSync(entries)
        let uniqueLocations = Set(entries.map { $0.location }).count
        
        // Mood calculations
        let activityMoods = Dictionary(grouping: entries.filter { $0.activity != nil }, by: { $0.activity! })
            .mapValues { $0.reduce(0.0) { $0 + $1.moodValue } / Double($0.count) }
            .sorted { $0.value > $1.value }
        let artistMoods = Dictionary(grouping: entries, by: { $0.song.artist })
            .mapValues { $0.reduce(0.0) { $0 + $1.moodValue } / Double($0.count) }
            .sorted { $0.value > $1.value }
        let majorEntries = entries.filter { $0.mode == 1 }
        let minorEntries = entries.filter { $0.mode == 0 }
        let majorMood = majorEntries.isEmpty ? 0 : majorEntries.reduce(0.0) { $0 + $1.moodValue } / Double(majorEntries.count)
        let minorMood = minorEntries.isEmpty ? 0 : minorEntries.reduce(0.0) { $0 + $1.moodValue } / Double(minorEntries.count)
        let averageNostalgia = entries.isEmpty ? 0 : entries.reduce(0.0) { $0 + $1.nostalgiaValue } / Double(entries.count)
        
        // Social calculations
        let aloneCount = entries.filter { $0.company == "Alone" }.count
        let togetherCount = entries.count - aloneCount
        let companyCounts = Dictionary(grouping: entries.compactMap { $0.company }, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        let liveCount = entries.filter { $0.isLivePerformance }.count
        
        return CachedInsights(
            timeRange: timeRange,
            entryCount: entries.count,
            uniqueSongs: uniqueSongs,
            uniqueArtists: uniqueArtists,
            averageMood: averageMood,
            currentStreak: currentStreak,
            mostActiveHour: mostActiveHour,
            hourCounts: hourCounts,
            weekdayCounts: weekdayCounts,
            timeOfDayCounts: timeOfDayCounts,
            audioFeatures: audioFeatures,
            keyCounts: keyCounts,
            averageAcousticness: avgAcousticness,
            locationCounts: Array(locationCounts.prefix(10)),
            totalDistance: totalDistance,
            uniqueLocations: uniqueLocations,
            activityMoods: Array(activityMoods),
            artistMoods: Array(artistMoods),
            majorMinorMoods: (major: majorMood, minor: minorMood),
            averageNostalgia: averageNostalgia,
            aloneVsTogether: (alone: aloneCount, together: togetherCount),
            companyCounts: Array(companyCounts),
            livePerformanceCount: liveCount
        )
    }
    
    // MARK: - Helper Calculation Functions
    
    private func calculateAverageValue(_ entries: [JournalEntry], keyPath: KeyPath<JournalEntry, Double?>) -> Double {
        let values = entries.compactMap { $0[keyPath: keyPath] }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    private func calculateStreakSync(entries: [JournalEntry]) -> Int? {
        guard !entries.isEmpty else { return nil }
        
        let sortedEntries = entries.sorted { $0.date > $1.date }
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date.now)
        
        for entry in sortedEntries {
            let entryDate = calendar.startOfDay(for: entry.date)
            let daysDiff = calendar.dateComponents([.day], from: entryDate, to: checkDate).day ?? 0
            
            if daysDiff == 0 {
                streak += 1
            } else if daysDiff == 1 {
                streak += 1
                checkDate = entryDate
            } else {
                break
            }
        }
        
        return streak > 0 ? streak : nil
    }
    
    private func calculateTotalDistanceSync(_ entries: [JournalEntry]) -> Double {
        guard entries.count > 1 else { return 0 }
        
        var totalDistance: Double = 0
        let sortedEntries = entries.sorted { $0.date < $1.date }
        
        for i in 0..<(sortedEntries.count - 1) {
            let from = sortedEntries[i]
            let to = sortedEntries[i + 1]
            totalDistance += calculateDistance(
                from: (from.latitude, from.longitude),
                to: (to.latitude, to.longitude)
            )
        }
        
        return totalDistance
    }
    
    private func calculateDistance(from: (lat: Double, lon: Double), to: (lat: Double, lon: Double)) -> Double {
        let earthRadius = 6371000.0
        let dLat = (to.lat - from.lat) * .pi / 180
        let dLon = (to.lon - from.lon) * .pi / 180
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(from.lat * .pi / 180) * cos(to.lat * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }
    
    private func getTimeOfDay(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<21: return "Evening"
        default: return "Night"
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 80))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text("No Insights Yet")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Create journal entries to unlock fascinating patterns about your music habits!")
                .font(.body)
                .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .foregroundColor(themeManager.currentTheme.primaryTextColor)
    }
    
    private var noDataForRangeView: some View {
        VStack(spacing: 15) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text("No Entries in This Period")
                .font(.headline)
            
            Text("Try selecting a different time range")
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .foregroundColor(themeManager.currentTheme.primaryTextColor)
        .padding(.vertical, 40)
    }
    
    // MARK: - UI Components
    
    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InsightCategory.allCases) { category in
                    Button(action: { selectedInsightCategory = category }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.caption)
                            Text(category.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            selectedInsightCategory == category ?
                            themeManager.currentTheme.accentColor :
                            themeManager.currentTheme.secondaryBackgroundColor
                        )
                        .foregroundColor(
                            selectedInsightCategory == category ?
                            .white :
                            themeManager.currentTheme.primaryTextColor
                        )
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 15)
        }
    }
    
    // MARK: - Overview Insights
    
    private var overviewInsights: some View {
        Group {
            if let cache = cachedInsights {
                VStack(spacing: 25) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        StatCard(title: "Entries", value: "\(cache.entryCount)", icon: "book.fill", color: themeManager.currentTheme.accentColor)
                        StatCard(title: "Unique Songs", value: "\(cache.uniqueSongs)", icon: "music.note", color: .blue)
                        StatCard(title: "Artists", value: "\(cache.uniqueArtists)", icon: "person.fill", color: .purple)
                        StatCard(title: "Avg Mood", value: String(format: "%.0f%%", cache.averageMood), icon: "face.smiling", color: .green)
                    }
                    
                    if let streak = cache.currentStreak {
                        InsightCard(title: "Current Streak", icon: "flame.fill", iconColor: .orange) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(streak) days")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    Text("Keep it going!")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                }
                                Spacer()
                            }
                        }
                    }
                    
                    if let hour = cache.mostActiveHour {
                        InsightCard(title: "Peak Journaling Hour", icon: "clock.fill", iconColor: .blue) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(formatHour(hour))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                Text("Your most active time")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                    }
                    
                    moodTrendChart
                }
            }
        }
    }
    
    // MARK: - Recommendations (Using Cache)
    
    private var recommendationsInsights: some View {
        Group {
            if let cache = cachedInsights {
                VStack(spacing: 25) {
                    SectionHeader(title: "Personalized For You", subtitle: "Smart suggestions based on your patterns")
                    
                    // Best time recommendation
                    if let hour = cache.mostActiveHour, cache.entryCount >= 3 {
                        RecommendationCard(title: "Your Prime Journaling Time", icon: "clock.badge.checkmark.fill", iconColor: .blue, category: "Timing") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("You journal most around \(formatHour(hour))")
                                    .font(.headline)
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                Text("Try setting a daily reminder for this time to maintain your streak!")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                    }
                    
                    // Mood boosting artists
                    let topMoodArtists = cache.artistMoods.filter { $0.1 > 75 }.prefix(3)
                    if !topMoodArtists.isEmpty {
                        RecommendationCard(title: "Mood Boosters", icon: "heart.circle.fill", iconColor: .pink, category: "Artists") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("These artists consistently boost your mood:")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                
                                ForEach(Array(topMoodArtists), id: \.0) { artist, avgMood in
                                    HStack {
                                        Image(systemName: "music.note")
                                            .foregroundColor(.pink)
                                        Text(artist)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text("\(Int(avgMood))%")
                                            .font(.caption)
                                            .foregroundColor(.pink)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.pink.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                }
                            }
                        }
                    }
                    
                    // Social listening
                    let alonePercentage = Double(cache.aloneVsTogether.alone) / Double(cache.entryCount) * 100
                    if cache.entryCount >= 5 && alonePercentage > 80 {
                        RecommendationCard(title: "Social Listening Suggestion", icon: "person.2.fill", iconColor: .blue, category: "Social") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(Int(alonePercentage))% of your listening is solo")
                                    .font(.headline)
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                Text("Try sharing music with friends - social listening creates memorable moments!")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                    }
                    
                    // More recommendations...
                    Text("More personalized recommendations coming soon!")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
    }
    
    // MARK: - Other Category Views (Optimized with Cache)
    
    private var temporalInsights: some View {
        Group {
            if let cache = cachedInsights {
                VStack(spacing: 25) {
                    SectionHeader(title: "When You Listen", subtitle: "Uncover your daily patterns")
                    
                    InsightCard(title: "24-Hour Activity", icon: "clock.arrow.circlepath", iconColor: .orange) {
                        Chart {
                            ForEach(Array(0...23), id: \.self) { hour in
                                BarMark(x: .value("Hour", hour), y: .value("Count", cache.hourCounts[hour] ?? 0))
                                    .foregroundStyle(themeManager.currentTheme.accentColor)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                                if let hour = value.as(Int.self) {
                                    AxisValueLabel { Text("\(hour)h").font(.caption2) }
                                }
                            }
                        }
                        .frame(height: 150)
                    }
                    
                    InsightCard(title: "Weekly Pattern", icon: "calendar", iconColor: .blue) {
                        let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                        Chart {
                            ForEach(1...7, id: \.self) { weekday in
                                BarMark(x: .value("Day", weekdays[weekday - 1]), y: .value("Count", cache.weekdayCounts[weekday] ?? 0))
                                    .foregroundStyle(themeManager.currentTheme.accentColor)
                            }
                        }
                        .frame(height: 150)
                    }
                }
            }
        }
    }
    
    private var musicalDNAInsights: some View {
        Group {
            if let cache = cachedInsights {
                VStack(spacing: 25) {
                    SectionHeader(title: "Your Musical Fingerprint", subtitle: "The science behind your taste")
                    
                    InsightCard(title: "Audio Characteristics", icon: "waveform.circle.fill", iconColor: .purple) {
                        VStack(spacing: 15) {
                            AudioFeatureBar(label: "Energy", value: cache.audioFeatures.energy, icon: "bolt.fill", color: .orange)
                            AudioFeatureBar(label: "Danceability", value: cache.audioFeatures.danceability, icon: "figure.dance", color: .purple)
                            AudioFeatureBar(label: "Positivity", value: cache.audioFeatures.valence, icon: "sun.max.fill", color: .yellow)
                            AudioFeatureBar(label: "Acoustic", value: cache.audioFeatures.acousticness, icon: "guitars.fill", color: .brown)
                        }
                    }
                }
            }
        }
    }
    
    private var locationInsights: some View {
        Group {
            if let cache = cachedInsights {
                VStack(spacing: 25) {
                    SectionHeader(title: "Your Music Geography", subtitle: "Where the magic happens")
                    
                    InsightCard(title: "Top Listening Spots", icon: "mappin.circle.fill", iconColor: .red) {
                        VStack(spacing: 12) {
                            ForEach(Array(cache.locationCounts.prefix(5)), id: \.0) { location, count in
                                HStack {
                                    Text(location).font(.subheadline).lineLimit(1)
                                    Spacer()
                                    Text("\(count)").font(.headline).foregroundColor(themeManager.currentTheme.accentColor)
                                }
                            }
                        }
                    }
                    
                    InsightCard(title: "Distance Traveled", icon: "figure.walk", iconColor: .green) {
                        VStack(spacing: 8) {
                            Text(String(format: "%.1f km", cache.totalDistance / 1000))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            Text("Your music journey")
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                }
            }
        }
    }
    
    private var moodScienceInsights: some View {
        Group {
            if let cache = cachedInsights {
                VStack(spacing: 25) {
                    SectionHeader(title: "Mood Patterns", subtitle: "The psychology of your listening")
                    
                    moodTrendChart
                    
                    InsightCard(title: "Major vs Minor Keys & Mood", icon: "music.quarternote.3", iconColor: .blue) {
                        HStack(spacing: 30) {
                            VStack {
                                Text("\(Int(cache.majorMinorMoods.major))%")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.green)
                                Text("Major Keys")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                            VStack {
                                Text("\(Int(cache.majorMinorMoods.minor))%")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.purple)
                                Text("Minor Keys")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
    
    private var socialInsights: some View {
        Group {
            if let cache = cachedInsights {
                VStack(spacing: 25) {
                    SectionHeader(title: "Social Listening", subtitle: "Who influences your soundtrack")
                    
                    InsightCard(title: "Alone vs With Others", icon: "person.2.fill", iconColor: .purple) {
                        Chart {
                            SectorMark(angle: .value("Count", cache.aloneVsTogether.alone), innerRadius: .ratio(0.5), angularInset: 2)
                                .foregroundStyle(.blue)
                                .annotation(position: .overlay) {
                                    Text("Alone\n\(cache.aloneVsTogether.alone)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                            SectorMark(angle: .value("Count", cache.aloneVsTogether.together), innerRadius: .ratio(0.5), angularInset: 2)
                                .foregroundStyle(.purple)
                                .annotation(position: .overlay) {
                                    Text("Together\n\(cache.aloneVsTogether.together)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                        }
                        .frame(height: 200)
                    }
                    
                    InsightCard(title: "Live Performance Ratio", icon: "ticket.fill", iconColor: .red) {
                        let percentage = cache.entryCount == 0 ? 0 : (Double(cache.livePerformanceCount) / Double(cache.entryCount)) * 100
                        VStack(spacing: 8) {
                            Text("\(cache.livePerformanceCount)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            Text(String(format: "%.1f%% of entries", percentage))
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                }
            }
        }
    }
    
    private var moodTrendChart: some View {
        InsightCard(title: "Mood Over Time", icon: "chart.line.uptrend.xyaxis", iconColor: .green) {
            if filteredEntries.count >= 2 {
                Chart {
                    ForEach(filteredEntries.sorted(by: { $0.date < $1.date })) { entry in
                        LineMark(x: .value("Date", entry.date), y: .value("Mood", entry.moodValue))
                            .foregroundStyle(themeManager.currentTheme.accentColor)
                            .interpolationMethod(.catmullRom)
                        AreaMark(x: .value("Date", entry.date), y: .value("Mood", entry.moodValue))
                            .foregroundStyle(LinearGradient(colors: [themeManager.currentTheme.accentColor.opacity(0.3), themeManager.currentTheme.accentColor.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 0...100)
                .frame(height: 180)
            } else {
                Text("Need at least 2 entries")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let subtitle: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

struct InsightCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    @EnvironmentObject var themeManager: ThemeManager
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct AudioFeatureBar: View {
    let label: String
    let value: Double
    let icon: String
    let color: Color
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.0f%%", value * 100))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(themeManager.currentTheme.primaryBackgroundColor.opacity(0.3))
                        .frame(height: 6)
                        .cornerRadius(3)
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * value, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .foregroundColor(themeManager.currentTheme.primaryTextColor)
    }
}

struct RecommendationCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let category: String
    let content: Content
    
    @EnvironmentObject var themeManager: ThemeManager
    
    init(title: String, icon: String, iconColor: Color, category: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.category = category
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(iconColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        Text(category.uppercased())
                            .font(.caption2)
                            .foregroundColor(iconColor)
                            .fontWeight(.semibold)
                    }
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(iconColor.opacity(0.6))
            }
            Divider()
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(LinearGradient(colors: [themeManager.currentTheme.secondaryBackgroundColor, iconColor.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(iconColor.opacity(0.3), lineWidth: 1))
    }
}

#Preview {
    PreviewContainer {
        InsightsView()
    }
}
