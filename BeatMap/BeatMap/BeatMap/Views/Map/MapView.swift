// MARK: - File Header
//
// MapView.swift
// BeatMap
//
// Version: 2.1.0 (Enhanced Map with Cluster Selection)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI
import MapKit

/// Interactive 3D map displaying all BeatMap journal entries at their locations.
/// Features intelligent clustering, multiple map styles, and advanced filtering.
struct MapView: View {

    // MARK: - Environment & State
    
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var locationManager: LocationManager

    @State private var selectedEntryID: JournalEntry.ID?
    @State private var entryForSheet: JournalEntry?
    @State private var clusterForSheet: EntryCluster?
    @State private var showingFilters = false
    @State private var showingStats = false
    @State private var selectedMapStyle: MapStyleOption = .standard
    
    // Filter states
    @State private var filterDateRange: DateRange = .allTime
    @State private var searchText = ""
    @State private var selectedGenre: String?
    
    // Map camera with intelligent initial positioning
    @State private var cameraPosition: MapCameraPosition = .automatic

    // MARK: - Enums
    
    enum MapStyleOption: String, CaseIterable, Identifiable {
        case standard = "Standard"
        case satellite = "Satellite"
        case hybrid = "Hybrid"
        
        var id: String { rawValue }
        
        var mapStyle: MapStyle {
            switch self {
            case .standard:
                return .standard(elevation: .realistic)
            case .satellite:
                return .imagery(elevation: .realistic)
            case .hybrid:
                return .hybrid(elevation: .realistic)
            }
        }
    }
    
    enum DateRange: String, CaseIterable, Identifiable {
        case allTime = "All Time"
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        case lastYear = "Last Year"
        
        var id: String { rawValue }
        
        func filterDate() -> Date? {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .allTime:
                return nil
            case .lastWeek:
                return calendar.date(byAdding: .day, value: -7, to: now)
            case .lastMonth:
                return calendar.date(byAdding: .month, value: -1, to: now)
            case .lastYear:
                return calendar.date(byAdding: .year, value: -1, to: now)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Filters entries based on current filter settings
    private var filteredEntries: [JournalEntry] {
        var entries = journalStore.entries
        
        // Date range filter
        if let filterDate = filterDateRange.filterDate() {
            entries = entries.filter { $0.date >= filterDate }
        }
        
        // Search filter
        if !searchText.isEmpty {
            entries = entries.filter {
                $0.song.title.localizedCaseInsensitiveContains(searchText) ||
                $0.song.artist.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Genre filter
        if let genre = selectedGenre {
            entries = entries.filter { $0.genre?.localizedCaseInsensitiveContains(genre) ?? false }
        }
        
        return entries
    }
    
    /// Groups nearby entries for clustering
    private var clusteredEntries: [EntryCluster] {
        let clusterDistance: CLLocationDistance = 100 // meters (reduced for better clustering)
        var clusters: [EntryCluster] = []
        var processedEntries: Set<UUID> = []
        
        for entry in filteredEntries {
            guard !processedEntries.contains(entry.id) else { continue }
            
            let entryLocation = CLLocation(latitude: entry.latitude, longitude: entry.longitude)
            var clusterEntries: [JournalEntry] = [entry]
            processedEntries.insert(entry.id)
            
            // Find nearby entries
            for otherEntry in filteredEntries {
                guard !processedEntries.contains(otherEntry.id) else { continue }
                
                let otherLocation = CLLocation(latitude: otherEntry.latitude, longitude: otherEntry.longitude)
                let distance = entryLocation.distance(from: otherLocation)
                
                if distance < clusterDistance {
                    clusterEntries.append(otherEntry)
                    processedEntries.insert(otherEntry.id)
                }
            }
            
            clusters.append(EntryCluster(entries: clusterEntries))
        }
        
        return clusters
    }
    
    /// Available genres for filtering
    private var availableGenres: [String] {
        let genres = Set(journalStore.entries.compactMap { $0.genre })
        return Array(genres).sorted()
    }
    
    /// Statistics about visible entries
    private var stats: MapStats {
        MapStats(
            totalEntries: filteredEntries.count,
            uniqueLocations: Set(filteredEntries.map { "\($0.latitude),\($0.longitude)" }).count,
            topGenre: topGenre(),
            dateRange: "\(filteredEntries.map { $0.date }.min()?.formatted(date: .abbreviated, time: .omitted) ?? "N/A") - \(filteredEntries.map { $0.date }.max()?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")"
        )
    }
    
    private func topGenre() -> String {
        let genreCounts = Dictionary(grouping: filteredEntries.compactMap { $0.genre }, by: { $0 })
            .mapValues { $0.count }
        return genreCounts.max(by: { $0.value < $1.value })?.key ?? "N/A"
    }

    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main map
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom, .pitch, .rotate], selection: $selectedEntryID) {
                ForEach(clusteredEntries) { cluster in
                    if cluster.entries.count == 1 {
                        // Single entry marker
                        let entry = cluster.entries[0]
                        Annotation(
                            entry.song.title,
                            coordinate: cluster.coordinate
                        ) {
                            SingleEntryMarker(entry: entry)
                                .environmentObject(themeManager)
                        }
                        .tag(entry.id)
                    } else {
                        // Cluster marker - now tappable to show list
                        Annotation(
                            "\(cluster.entries.count) entries",
                            coordinate: cluster.coordinate
                        ) {
                            ClusterMarker(count: cluster.entries.count, entries: cluster.entries)
                                .environmentObject(themeManager)
                                .onTapGesture {
                                    clusterForSheet = cluster
                                }
                        }
                    }
                }
            }
            .mapStyle(selectedMapStyle.mapStyle)
            .mapControls {
                MapCompass()
                MapScaleView()
                MapPitchToggle()
            }
            
            // Control panel overlay
            VStack(alignment: .trailing, spacing: 12) {
                // Map style selector
                Menu {
                    ForEach(MapStyleOption.allCases) { style in
                        Button(action: { selectedMapStyle = style }) {
                            Label(style.rawValue, systemImage: selectedMapStyle == style ? "checkmark" : "")
                        }
                    }
                } label: {
                    Image(systemName: "map")
                        .font(.title3)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
                
                // Filter button
                Button(action: { showingFilters.toggle() }) {
                    Image(systemName: filterDateRange != .allTime || !searchText.isEmpty || selectedGenre != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                        .foregroundColor(filterDateRange != .allTime || !searchText.isEmpty || selectedGenre != nil ? themeManager.currentTheme.accentColor : .primary)
                }
                
                // Statistics button
                Button(action: { showingStats.toggle() }) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
                
                // Center on user location
                Button(action: centerOnUserLocation) {
                    Image(systemName: "location.fill")
                        .font(.title3)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
                
                // Fit all entries
                Button(action: fitAllEntries) {
                    Image(systemName: "scope")
                        .font(.title3)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
            }
            .padding()
            
            // Statistics panel
            if showingStats {
                VStack {
                    Spacer()
                    StatsPanel(stats: stats)
                        .environmentObject(themeManager)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onChange(of: selectedEntryID) {
            guard let selectedID = selectedEntryID else { return }
            entryForSheet = journalStore.entries.first { $0.id == selectedID }
        }
        .sheet(item: $entryForSheet) { entry in
            JournalDetailView(entry: entry)
                .environmentObject(themeManager)
                .environmentObject(journalStore)
        }
        .sheet(item: $clusterForSheet) { cluster in
            ClusterSelectionSheet(cluster: cluster, onSelectEntry: { entry in
                clusterForSheet = nil
                // Small delay to allow sheet to dismiss before showing detail
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    entryForSheet = entry
                }
            })
            .environmentObject(themeManager)
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheet(
                dateRange: $filterDateRange,
                searchText: $searchText,
                selectedGenre: $selectedGenre,
                availableGenres: availableGenres
            )
            .environmentObject(themeManager)
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            // Set initial camera position to show all entries
            if cameraPosition == .automatic {
                fitAllEntries()
            }
        }
    }

    // MARK: - Helper Functions

    /// Animates the map camera to center on the user's current location
    private func centerOnUserLocation() {
        print("🗺️ Centering map on user location...")
        
        if let userLocation = locationManager.currentLocation {
            withAnimation(.easeInOut(duration: 1.0)) {
                cameraPosition = .camera(
                    MapCamera(
                        centerCoordinate: userLocation.coordinate,
                        distance: 5000,
                        heading: 0,
                        pitch: 45
                    )
                )
            }
            print("✅ Map centered")
        } else {
            print("⚠️ User location unknown")
        }
    }
    
    /// Fits all visible entries in the map view
    private func fitAllEntries() {
        guard !filteredEntries.isEmpty else { return }
        
        let coordinates = filteredEntries.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        
        let region = regionForCoordinates(coordinates)
        
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .region(region)
        }
    }
    
    /// Calculates a region that encompasses all given coordinates
    private func regionForCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
            )
        }
        
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5, // Add 50% padding
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Supporting Views

/// Marker for a single entry with circular album art
struct SingleEntryMarker: View {
    let entry: JournalEntry
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            AlbumArtView(song: entry.song, size: 50)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 3)
                )
                .shadow(radius: 5)
            
            Image(systemName: "arrowtriangle.down.fill")
                .font(.caption)
                .foregroundColor(.white)
                .offset(y: -6)
        }
    }
}

/// Marker for clustered entries
struct ClusterMarker: View {
    let count: Int
    let entries: [JournalEntry]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            Circle()
                .fill(themeManager.currentTheme.accentColor)
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 3)
                )
            
            VStack(spacing: 2) {
                Image(systemName: "music.note.list")
                    .font(.title3)
                    .foregroundColor(.white)
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .shadow(radius: 5)
    }
}

/// Sheet to select from multiple entries at the same location
struct ClusterSelectionSheet: View {
    let cluster: EntryCluster
    let onSelectEntry: (JournalEntry) -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        // Location header
                        VStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(themeManager.currentTheme.accentColor)
                            
                            Text(cluster.entries.first?.location ?? "Unknown Location")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Text("\(cluster.entries.count) entries at this location")
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        .padding()
                        
                        // List of entries
                        ForEach(cluster.entries.sorted(by: { $0.date > $1.date })) { entry in
                            Button(action: {
                                onSelectEntry(entry)
                            }) {
                                HStack(spacing: 15) {
                                    // Circular album art
                                    AlbumArtView(song: entry.song, size: 60)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .strokeBorder(themeManager.currentTheme.accentColor.opacity(0.3), lineWidth: 2)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.song.title)
                                            .font(.headline)
                                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                            .lineLimit(1)
                                        
                                        Text(entry.song.artist)
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                            .lineLimit(1)
                                        
                                        Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                }
                                .padding()
                                .background(themeManager.currentTheme.secondaryBackgroundColor)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

/// Statistics panel overlay
struct StatsPanel: View {
    let stats: MapStats
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Map Statistics")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                StatRow(icon: "music.note.list", label: "Total Entries", value: "\(stats.totalEntries)")
                StatRow(icon: "mappin.and.ellipse", label: "Unique Locations", value: "\(stats.uniqueLocations)")
                StatRow(icon: "guitars", label: "Top Genre", value: stats.topGenre)
                StatRow(icon: "calendar", label: "Date Range", value: stats.dateRange)
            }
        }
        .padding()
        .background(.ultraThickMaterial)
        .cornerRadius(15)
        .shadow(radius: 10)
        .foregroundColor(themeManager.currentTheme.primaryTextColor)
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .frame(width: 20)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

/// Filter sheet
struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @Binding var dateRange: MapView.DateRange
    @Binding var searchText: String
    @Binding var selectedGenre: String?
    let availableGenres: [String]
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea()
                
                Form {
                    // Search
                    Section(header: Text("Search")) {
                        TextField("Search songs, artists, locations...", text: $searchText)
                    }
                    .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                    
                    // Date Range
                    Section(header: Text("Date Range")) {
                        Picker("Date Range", selection: $dateRange) {
                            ForEach(MapView.DateRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                    
                    // Genre Filter
                    Section(header: Text("Genre")) {
                        Picker("Genre", selection: $selectedGenre) {
                            Text("All Genres").tag(nil as String?)
                            ForEach(availableGenres, id: \.self) { genre in
                                Text(genre).tag(genre as String?)
                            }
                        }
                    }
                    .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                    
                    // Reset
                    Section {
                        Button("Reset All Filters") {
                            dateRange = .allTime
                            searchText = ""
                            selectedGenre = nil
                        }
                        .foregroundColor(.red)
                    }
                    .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Models

struct EntryCluster: Identifiable {
    let id = UUID()
    let entries: [JournalEntry]
    
    var coordinate: CLLocationCoordinate2D {
        let avgLat = entries.map { $0.latitude }.reduce(0, +) / Double(entries.count)
        let avgLon = entries.map { $0.longitude }.reduce(0, +) / Double(entries.count)
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }
}

struct MapStats {
    let totalEntries: Int
    let uniqueLocations: Int
    let topGenre: String
    let dateRange: String
}

#Preview {
    PreviewContainer {
        MapView()
    }
}
