// MARK: - File Header
//
// MapView.swift
// BeatMap
//
// Version: 1.1.0 (Smart Clustering)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI
import MapKit

// MARK: - Cluster Data Model

/// Represents a cluster of journal entries at a similar location
struct EntryCluster: Identifiable {
    let id = UUID()
    let entries: [JournalEntry]
    let centerCoordinate: CLLocationCoordinate2D
    
    var count: Int { entries.count }
    var isCluster: Bool { entries.count > 1 }
    var primaryEntry: JournalEntry { entries.first! }
}

// MARK: - Main Map View

/// Interactive 3D map displaying all BeatMap journal entries at their locations.
/// Features smart clustering that groups nearby entries when zoomed out.
struct MapView: View {

    // MARK: - Environment & State
    
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var locationManager: LocationManager

    @State private var selectedClusterID: UUID?
    @State private var entryForSheet: JournalEntry?
    @State private var clusterForSheet: EntryCluster?
    @State private var currentDistance: Double = 10_000_000 // Track zoom level
    @State private var clusters: [EntryCluster] = []

    /// Map camera starting with a global perspective
    @State private var cameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 40, longitude: 0),
            distance: 10_000_000, // Global view (meters)
            heading: 0,
            pitch: 60 // 3D tilt angle
        )
    )

    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Map with smart clustering annotations
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom, .pitch, .rotate], selection: $selectedClusterID) {
                ForEach(clusters) { cluster in
                    Annotation(
                        cluster.primaryEntry.song.title,
                        coordinate: cluster.centerCoordinate
                    ) {
                        ClusterAnnotationView(cluster: cluster)
                            .environmentObject(themeManager)
                            .onTapGesture {
                                handleClusterTap(cluster)
                            }
                    }
                    .tag(cluster.id)
                }
            }
            .mapStyle(.imagery(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
                MapPitchToggle()
            }
            .onMapCameraChange(frequency: .continuous) { context in
                currentDistance = context.camera.distance
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                updateClusters()
            }

            // User location button
            Button(action: centerOnUserLocation) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
        }
        .sheet(item: $entryForSheet) { entry in
            JournalDetailView(entry: entry)
                .environmentObject(themeManager)
                .environmentObject(journalStore)
        }
        .sheet(item: $clusterForSheet) { cluster in
            ClusterDetailView(cluster: cluster, onSelectEntry: { entry in
                clusterForSheet = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    entryForSheet = entry
                }
            })
            .environmentObject(themeManager)
        }
        .onAppear {
            updateClusters()
        }
        .onChange(of: journalStore.entries) {
            updateClusters()
        }
    }

    // MARK: - Clustering Logic

    /// Updates clusters based on current zoom level and entry positions
    private func updateClusters() {
        print("🎯 Updating clusters at distance: \(currentDistance)m")
        
        let entries = journalStore.entries
        guard !entries.isEmpty else {
            clusters = []
            return
        }
        
        // Calculate clustering radius based on zoom level
        // More zoomed out = larger radius = more aggressive clustering
        let clusterRadius = calculateClusterRadius(for: currentDistance)
        
        // Perform clustering
        var processedEntries = Set<UUID>()
        var newClusters: [EntryCluster] = []
        
        for entry in entries {
            guard !processedEntries.contains(entry.id) else { continue }
            
            let entryCoord = CLLocationCoordinate2D(latitude: entry.latitude, longitude: entry.longitude)
            var clusterEntries = [entry]
            processedEntries.insert(entry.id)
            
            // Find nearby entries to cluster
            for otherEntry in entries {
                guard !processedEntries.contains(otherEntry.id) else { continue }
                
                let otherCoord = CLLocationCoordinate2D(latitude: otherEntry.latitude, longitude: otherEntry.longitude)
                let distance = entryCoord.distance(to: otherCoord)
                
                if distance < clusterRadius {
                    clusterEntries.append(otherEntry)
                    processedEntries.insert(otherEntry.id)
                }
            }
            
            // Calculate cluster center (average of all coordinates)
            let centerLat = clusterEntries.map { $0.latitude }.reduce(0, +) / Double(clusterEntries.count)
            let centerLon = clusterEntries.map { $0.longitude }.reduce(0, +) / Double(clusterEntries.count)
            
            newClusters.append(EntryCluster(
                entries: clusterEntries,
                centerCoordinate: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
            ))
        }
        
        clusters = newClusters
        print("✅ Created \(clusters.count) clusters from \(entries.count) entries")
        print("   - Single entries: \(clusters.filter { !$0.isCluster }.count)")
        print("   - Clustered groups: \(clusters.filter { $0.isCluster }.count)")
    }
    
    /// Calculates appropriate clustering radius based on map zoom level
    private func calculateClusterRadius(for distance: Double) -> Double {
        // Distance is in meters from the camera to the ground
        // Smaller distance = more zoomed in = smaller clustering radius
        
        if distance > 1_000_000 {
            return 500_000.0 // Very zoomed out: cluster within 500km
        } else if distance > 100_000 {
            return 50_000.0 // Zoomed out: cluster within 50km
        } else if distance > 10_000 {
            return 5_000.0 // Medium: cluster within 5km
        } else if distance > 1_000 {
            return 500.0 // Zoomed in: cluster within 500m
        } else {
            return 50.0 // Very zoomed in: cluster within 50m (minimal clustering)
        }
    }
    
    /// Handles tapping on a cluster annotation
    private func handleClusterTap(_ cluster: EntryCluster) {
        if cluster.isCluster {
            // Show cluster detail sheet
            clusterForSheet = cluster
        } else {
            // Show single entry detail
            entryForSheet = cluster.primaryEntry
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
}

// MARK: - Cluster Annotation View

/// Visual representation of a cluster on the map
struct ClusterAnnotationView: View {
    let cluster: EntryCluster
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            if cluster.isCluster {
                // Multiple entries - show count badge
                ZStack {
                    Circle()
                        .fill(themeManager.currentTheme.accentColor)
                        .frame(width: 50, height: 50)
                    
                    VStack(spacing: 2) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        Text("\(cluster.count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            } else {
                // Single entry - show album art
                AlbumArtView(song: cluster.primaryEntry.song, size: 44)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
        }
    }
}

// MARK: - Cluster Detail View

/// Sheet view showing all entries in a cluster
struct ClusterDetailView: View {
    let cluster: EntryCluster
    let onSelectEntry: (JournalEntry) -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 15) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 40))
                                .foregroundColor(themeManager.currentTheme.accentColor)
                            
                            Text("\(cluster.count) Entries Here")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(cluster.entries.first?.location ?? "Unknown Location")
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        .padding(.top)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Entry list
                        VStack(spacing: 12) {
                            ForEach(cluster.entries.sorted(by: { $0.date > $1.date })) { entry in
                                Button(action: {
                                    onSelectEntry(entry)
                                }) {
                                    HStack(spacing: 15) {
                                        AlbumArtView(song: entry.song, size: 60)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(entry.song.title)
                                                .font(.headline)
                                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                            
                                            Text(entry.song.artist)
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                            
                                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    }
                                    .padding()
                                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Entries at Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Coordinate Extension

extension CLLocationCoordinate2D {
    /// Calculates the distance in meters between two coordinates
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }
}

#Preview {
    PreviewContainer {
        MapView()
    }
}
