// MARK: - File Header
//
// NewEntryView.swift
// BeatMap
//
// Version: 1.2.0 (Comprehensive Spotify Data Tracking)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI
import CoreLocation
import MapKit

/// View for creating a new journal entry in BeatMap.
/// Now features live Spotify search and automatic audio feature capture!
struct NewEntryView: View {

    // MARK: - Environment & State
    
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedSong: Song?
    @State private var selectedArtistId: String?
    @State private var showingSongPicker = false
    
    // Spotify data state
    @State private var spotifyFeatures: AudioFeatures?
    @State private var spotifyGenres: [String]?
    @State private var isFetchingSpotifyData = false
    
    // Spotify search state
    @State private var searchQuery = ""
    @State private var searchResults: [TrackObject] = []
    @State private var isSearching = false

    @State private var journalText = ""
    @State private var nostalgiaValue = 50.0
    @State private var energyValue = 50.0
    @State private var moodValue = 50.0
    @State private var isLivePerformance = false
    @State private var selectedActivity: String = "Listening"
    @State private var selectedCompany: String = "Alone"
    
    let activities = ["Listening", "Working", "Commuting", "Exercising", "Relaxing", "Socializing", "Cooking", "Other"]
    let companies = ["Alone", "Partner", "Friends", "Family", "Coworkers", "Crowd", "Other"]

    @State private var entryCoordinate: CLLocationCoordinate2D?
    @State private var entryLocationString: String?
    @State private var isShowingLocationPicker = false
    @State private var showingSaveConfirmation = false

    init(preselectedSong: Song? = nil) {
        _selectedSong = State(initialValue: preselectedSong)
    }

    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Group {
                if selectedSong == nil {
                    songSearchView
                } else {
                    journalingStageView(for: selectedSong!)
                }
            }
            .navigationTitle(selectedSong == nil ? "Find a Song" : "New Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if selectedSong != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save", action: saveEntry)
                            .fontWeight(.bold)
                            .disabled(journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || entryCoordinate == nil)
                    }
                }
            }
            .background(themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea())
            .sheet(isPresented: $isShowingLocationPicker) {
                LocationPickerView(selectedCoordinate: $entryCoordinate, selectedLocationString: $entryLocationString)
            }
            .alert("Entry Saved!", isPresented: $showingSaveConfirmation, actions: {
                Button("OK") {
                    dismiss()
                }
            }, message: {
                Text("Your journal entry has been saved successfully.")
            })
        }
        .frame(minWidth: 400, idealWidth: 500, maxWidth: .infinity, minHeight: 500, idealHeight: 700, maxHeight: .infinity)
        .accentColor(themeManager.currentTheme.accentColor)
        .onAppear {
            setInitialLocation()
            
            // If song was preselected, fetch its Spotify data
            if let song = selectedSong, let artistId = selectedArtistId {
                Task {
                    await fetchAllSpotifyData(trackId: song.id, artistId: artistId)
                }
            }
        }
    }

    // MARK: - Song Search View
    
    private var songSearchView: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                TextField("Search songs or artists...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
            }
            .padding()
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
            .padding()
            
            if isSearching {
                Spacer()
                ProgressView("Searching Spotify...")
                    .tint(themeManager.currentTheme.accentColor)
                Spacer()
            } else if searchResults.isEmpty && !searchQuery.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 50))
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    Text("No results found")
                        .font(.headline)
                    Text("Try a different search")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                Spacer()
            } else if searchResults.isEmpty {
                Spacer()
                VStack(spacing: 15) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    Text("Search Spotify")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Find any song from millions of tracks")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
                .padding()
                Spacer()
            } else {
                List(searchResults) { track in
                    Button(action: {
                        selectTrack(track)
                    }) {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: track.album.images.first?.url ?? "")) { image in
                                image.resizable()
                            } placeholder: {
                                ZStack {
                                    themeManager.currentTheme.secondaryBackgroundColor
                                    ProgressView()
                                }
                            }
                            .frame(width: 50, height: 50)
                            .cornerRadius(6)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(track.name)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                Text(track.artists.first?.name ?? "Unknown Artist")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                            
                            Spacer()
                        }
                    }
                    .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(themeManager.currentTheme.primaryBackgroundColor)
        .onChange(of: searchQuery) {
            performSearch()
        }
    }

    // MARK: - Journaling Stage

    private func journalingStageView(for song: Song) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack {
                    HStack {
                        Button(action: {
                            selectedSong = nil
                            selectedArtistId = nil
                            searchResults = []
                            searchQuery = ""
                            spotifyFeatures = nil
                            spotifyGenres = nil
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Change Song")
                            }
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                        Spacer()
                        
                        if isFetchingSpotifyData {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Loading data...")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    AlbumArtView(song: song, size: 150)
                    Text(song.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(song.artist)
                        .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                    
                    if let genre = spotifyGenres?.first {
                        Text(genre)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(themeManager.currentTheme.accentColor.opacity(0.2))
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            .cornerRadius(12)
                    }
                }
                .padding(.top)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)

                VStack(spacing: 25) {
                    locationAndTimeInfo
                    journalingArea
                    
                    if let features = spotifyFeatures {
                        spotifyDataPreview(features: features)
                    }
                    
                    livePerformanceToggle
                    contextPickers
                    sliders
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    // MARK: - Helper Views

    private var locationAndTimeInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(themeManager.currentTheme.accentColor)
                Text(entryLocationString ?? "Unknown Location")
                    .font(.subheadline)
                Spacer()
                Button(action: { isShowingLocationPicker = true }) {
                    Text("Change")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(themeManager.currentTheme.accentColor)
                Text(Date.now.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
        .foregroundColor(themeManager.currentTheme.primaryTextColor)
    }

    private var journalingArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's on your mind?")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            TextEditor(text: $journalText)
                .frame(minHeight: 150)
                .padding(8)
                .background(themeManager.currentTheme.secondaryBackgroundColor)
                .cornerRadius(8)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
        }
    }

    private var livePerformanceToggle: some View {
        Toggle(isOn: $isLivePerformance) {
            HStack {
                Image(systemName: "music.mic")
                    .foregroundColor(themeManager.currentTheme.accentColor)
                Text("Live Performance")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
        .foregroundColor(themeManager.currentTheme.primaryTextColor)
    }

    private var contextPickers: some View {
        HStack(spacing: 15) {
            // Activity Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Activity")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Picker("Activity", selection: $selectedActivity) {
                    ForEach(activities, id: \.self) { activity in
                        Text(activity).tag(activity)
                    }
                }
                .pickerStyle(.menu)
                .padding(8)
                .background(themeManager.currentTheme.secondaryBackgroundColor)
                .cornerRadius(8)
            }
            
            // Company Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Company")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Picker("Company", selection: $selectedCompany) {
                    ForEach(companies, id: \.self) { company in
                        Text(company).tag(company)
                    }
                }
                .pickerStyle(.menu)
                .padding(8)
                .background(themeManager.currentTheme.secondaryBackgroundColor)
                .cornerRadius(8)
            }
        }
    }

    private var sliders: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    Text("Nostalgia")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(nostalgiaValue))")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                Slider(value: $nostalgiaValue, in: 0...100)
                    .tint(themeManager.currentTheme.accentColor)
            }
            .padding()
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
            .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    Text("Your Energy")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(energyValue))")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                Slider(value: $energyValue, in: 0...100)
                    .tint(themeManager.currentTheme.accentColor)
            }
            .padding()
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
            .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "face.smiling")
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    Text("Your Mood")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(moodValue))")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                Slider(value: $moodValue, in: 0...100)
                    .tint(themeManager.currentTheme.accentColor)
            }
            .padding()
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
            .foregroundColor(themeManager.currentTheme.primaryTextColor)
        }
    }
    
    /// Shows captured Spotify audio analysis
    private func spotifyDataPreview(features: AudioFeatures) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spotify Analysis Captured")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            HStack(spacing: 15) {
                if let tempo = features.tempo {
                    Label("\(Int(tempo)) BPM", systemImage: "metronome")
                        .font(.caption2)
                }
                if let energy = features.energy {
                    Label("Energy: \(Int(energy * 100))%", systemImage: "bolt.fill")
                        .font(.caption2)
                }
                if let valence = features.valence {
                    Label("Mood: \(Int(valence * 100))%", systemImage: "face.smiling")
                        .font(.caption2)
                }
            }
            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .padding()
        .background(themeManager.currentTheme.accentColor.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Spotify Search & Data Fetching
    
    private func performSearch() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await searchSpotify()
        }
    }
    
    @MainActor
    private func searchSpotify() async {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        let results = await SpotifyAPIManager.shared.searchForTracks(query: searchQuery)
        searchResults = results
        isSearching = false
    }
    
    private func selectTrack(_ track: TrackObject) {
        print("✅ Selected: \(track.name) by \(track.artists.first?.name ?? "Unknown")")
        
        selectedArtistId = track.artists.first?.id
        
        selectedSong = Song(
            id: track.id,
            title: track.name,
            artist: track.artists.first?.name ?? "Unknown Artist",
            albumArtURL: track.album.images.first?.url
        )
        
        Task {
            await fetchAllSpotifyData(trackId: track.id, artistId: selectedArtistId ?? "")
        }
    }
    
    @MainActor
    private func fetchAllSpotifyData(trackId: String, artistId: String) async {
        isFetchingSpotifyData = true
        print("📊 Fetching comprehensive Spotify data...")
        
        async let features = SpotifyAPIManager.shared.getAudioFeatures(for: trackId)
        async let artist = artistId.isEmpty ? nil : SpotifyAPIManager.shared.getArtistDetails(for: artistId)
        
        let (audioFeatures, artistDetails) = await (features, artist)
        
        spotifyFeatures = audioFeatures
        spotifyGenres = artistDetails?.genres
        
        isFetchingSpotifyData = false
        
        if let audioFeatures = audioFeatures {
            print("✅ Audio features loaded: Tempo \(audioFeatures.tempo ?? 0), Energy \(audioFeatures.energy ?? 0)")
        } else {
            print("⚠️ Audio features unavailable (may be restricted in development mode)")
        }
        
        if let genres = artistDetails?.genres, !genres.isEmpty {
            print("✅ Genres loaded: \(genres.joined(separator: ", "))")
        }
    }

    // MARK: - Data Management

    private func saveEntry() {
        guard let song = selectedSong,
              let coordinate = entryCoordinate,
              let locationStr = entryLocationString
        else {
            print("❌ Cannot save: Missing required data")
            print("   Song: \(selectedSong != nil ? "✅" : "❌")")
            print("   Location: \(entryCoordinate != nil ? "✅" : "❌")")
            print("   Location String: \(entryLocationString != nil ? "✅" : "❌")")
            return
        }

        print("💾 Saving entry with comprehensive Spotify data:")
        print("   Song: \(song.title) by \(song.artist)")
        print("   Location: \(locationStr)")
        print("   Journal text: \(journalText.count) characters")

        let newEntry = JournalEntry(
            id: UUID(),
            song: song,
            journalText: journalText,
            location: locationStr,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            date: .now,
            nostalgiaValue: nostalgiaValue,
            energyValue: energyValue,
            moodValue: moodValue,
            isLivePerformance: self.isLivePerformance,
            activity: self.selectedActivity,
            company: self.selectedCompany,
            genre: spotifyGenres?.first,
            tempo: spotifyFeatures?.tempo,
            spotifyEnergy: spotifyFeatures?.energy,
            danceability: spotifyFeatures?.danceability,
            valence: spotifyFeatures?.valence,
            acousticness: spotifyFeatures?.acousticness,
            instrumentalness: spotifyFeatures?.instrumentalness,
            liveness: spotifyFeatures?.liveness,
            speechiness: spotifyFeatures?.speechiness,
            key: spotifyFeatures?.key,
            mode: spotifyFeatures?.mode,
            timeSignature: spotifyFeatures?.time_signature,
            loudness: spotifyFeatures?.loudness,
            durationMs: spotifyFeatures?.duration_ms
        )

        print("📊 Captured Spotify data:")
        print("   - Genre: \(spotifyGenres?.first ?? "N/A")")
        print("   - Tempo: \(spotifyFeatures?.tempo ?? 0) BPM")
        print("   - Energy: \(spotifyFeatures?.energy ?? 0)")
        print("   - Valence: \(spotifyFeatures?.valence ?? 0)")
        
        journalStore.addEntry(newEntry)
        
        // Show confirmation before dismissing
        showingSaveConfirmation = true
    }

    private func setInitialLocation() {
        guard entryCoordinate == nil else { return }
        
        print("📍 Setting initial location for new entry...")
        
        Task {
            // Request fresh, high-accuracy location
            if let location = await locationManager.requestPreciseLocation() {
                entryCoordinate = location.coordinate
                entryLocationString = locationManager.locationName
                print("✅ Precise location set: \(locationManager.locationName)")
            } else {
                // Fallback to last known location or default
                if let currentCoord = locationManager.currentLocation?.coordinate {
                    entryCoordinate = currentCoord
                    entryLocationString = locationManager.locationName
                    print("⚠️ Using last known location")
                } else {
                    // Default to Newcastle city center
                    entryCoordinate = CLLocationCoordinate2D(latitude: 54.9783, longitude: -1.6178)
                    entryLocationString = "Newcastle Upon Tyne, UK"
                    print("⚠️ Using default location")
                }
            }
        }
    }
}

#Preview {
    PreviewContainer {
        NewEntryView()
    }
}
