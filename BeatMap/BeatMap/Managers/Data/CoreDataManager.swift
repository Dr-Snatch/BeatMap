// MARK: - File Header
//
// CoreDataManager.swift
// BeatMap
//
// Version: 1.1.0 (Core Data Migration)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import Foundation
import CoreData

/// Manages Core Data persistence for BeatMap journal entries.
/// Handles the Core Data stack, CRUD operations, and migration from UserDefaults.
class CoreDataManager {
    
    static let shared = CoreDataManager()
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BeatMap")
        
        // Enable automatic lightweight migration
        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❌ Core Data load error: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("✅ Core Data loaded successfully from: \(storeDescription.url?.lastPathComponent ?? "unknown")")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {
        print("🗄️ CoreDataManager initialized")
    }
    
    // MARK: - CRUD Operations
    
    /// Fetch all journal entries from Core Data
    func fetchAllEntries() -> [JournalEntry] {
        let fetchRequest: NSFetchRequest<CDJournalEntry> = CDJournalEntry.fetchRequest()
        
        // Sort by date descending (newest first)
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let cdEntries = try context.fetch(fetchRequest)
            let entries = cdEntries.compactMap { convertToJournalEntry($0) }
            print("✅ Fetched \(entries.count) entries from Core Data")
            return entries
        } catch {
            print("❌ Failed to fetch entries: \(error)")
            return []
        }
    }
    
    /// Save a new journal entry to Core Data
    func saveEntry(_ entry: JournalEntry) {
        let cdEntry = CDJournalEntry(context: context)
        updateCDEntry(cdEntry, with: entry)
        
        saveContext()
        print("✅ Entry saved to Core Data: \(entry.song.title)")
    }
    
    /// Update an existing journal entry in Core Data
    func updateEntry(_ entry: JournalEntry) {
        let fetchRequest: NSFetchRequest<CDJournalEntry> = CDJournalEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let cdEntry = results.first {
                updateCDEntry(cdEntry, with: entry)
                saveContext()
                print("✅ Entry updated in Core Data: \(entry.song.title)")
            } else {
                print("⚠️ Entry not found for update, creating new entry")
                saveEntry(entry)
            }
        } catch {
            print("❌ Failed to update entry: \(error)")
        }
    }
    
    /// Delete a journal entry from Core Data
    func deleteEntry(_ entry: JournalEntry) {
        let fetchRequest: NSFetchRequest<CDJournalEntry> = CDJournalEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let cdEntry = results.first {
                context.delete(cdEntry)
                saveContext()
                print("🗑️ Entry deleted from Core Data: \(entry.song.title)")
            }
        } catch {
            print("❌ Failed to delete entry: \(error)")
        }
    }
    
    /// Delete entries at specific offsets
    func deleteEntries(at offsets: IndexSet, from entries: [JournalEntry]) {
        for index in offsets {
            let entry = entries[index]
            deleteEntry(entry)
        }
    }
    
    /// Delete all journal entries from Core Data
    func deleteAllEntries() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDJournalEntry.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(batchDeleteRequest)
            saveContext()
            print("🗑️ All entries deleted from Core Data")
        } catch {
            print("❌ Failed to delete all entries: \(error)")
        }
    }
    
    // MARK: - Data Migration
    
    /// Migrate journal entries from UserDefaults to Core Data
    func migrateFromUserDefaults() {
        // Check if migration has already been performed
        let migrationKey = "beatmap.coredata.migrated"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            print("ℹ️ Migration already completed, skipping")
            return
        }
        
        print("🔄 Starting migration from UserDefaults to Core Data...")
        
        // Load entries from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "beatmap.journalEntries"),
              let entries = try? JSONDecoder().decode([JournalEntry].self, from: data) else {
            print("ℹ️ No UserDefaults data to migrate")
            UserDefaults.standard.set(true, forKey: migrationKey)
            return
        }
        
        print("📦 Found \(entries.count) entries to migrate")
        
        // Save each entry to Core Data
        for entry in entries {
            saveEntry(entry)
        }
        
        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
        print("✅ Migration completed: \(entries.count) entries migrated to Core Data")
        
        // Optional: Remove old UserDefaults data after successful migration
        UserDefaults.standard.removeObject(forKey: "beatmap.journalEntries")
        print("🧹 Cleaned up UserDefaults data")
    }
    
    // MARK: - Helper Methods
    
    /// Save the Core Data context
    private func saveContext() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("❌ Core Data save error: \(nsError), \(nsError.userInfo)")
        }
    }
    
    /// Convert CDJournalEntry (Core Data) to JournalEntry (Swift struct)
    private func convertToJournalEntry(_ cdEntry: CDJournalEntry) -> JournalEntry? {
        guard let id = cdEntry.id,
              let songId = cdEntry.songId,
              let songTitle = cdEntry.songTitle,
              let songArtist = cdEntry.songArtist,
              let journalText = cdEntry.journalText,
              let location = cdEntry.location,
              let date = cdEntry.date else {
            print("⚠️ Invalid CDJournalEntry data")
            return nil
        }
        
        let song = Song(
            id: songId,
            title: songTitle,
            artist: songArtist,
            albumArtURL: cdEntry.albumArtURL,
            albumArtSymbol: cdEntry.albumArtSymbol
        )
        
        return JournalEntry(
            id: id,
            song: song,
            journalText: journalText,
            location: location,
            latitude: cdEntry.latitude,
            longitude: cdEntry.longitude,
            date: date,
            nostalgiaValue: cdEntry.nostalgiaValue,
            energyValue: cdEntry.energyValue,
            moodValue: cdEntry.moodValue,
            isLivePerformance: cdEntry.isLivePerformance,
            activity: cdEntry.activity,
            company: cdEntry.company,
            genre: cdEntry.genre,
            tempo: cdEntry.tempo == 0 ? nil : cdEntry.tempo,
            spotifyEnergy: cdEntry.spotifyEnergy == 0 ? nil : cdEntry.spotifyEnergy,
            danceability: cdEntry.danceability == 0 ? nil : cdEntry.danceability,
            valence: cdEntry.valence == 0 ? nil : cdEntry.valence,
            acousticness: cdEntry.acousticness == 0 ? nil : cdEntry.acousticness,
            instrumentalness: cdEntry.instrumentalness == 0 ? nil : cdEntry.instrumentalness,
            liveness: cdEntry.liveness == 0 ? nil : cdEntry.liveness,
            speechiness: cdEntry.speechiness == 0 ? nil : cdEntry.speechiness,
            key: Int(cdEntry.key) == -1 ? nil : Int(cdEntry.key),
            mode: Int(cdEntry.mode) == -1 ? nil : Int(cdEntry.mode),
            timeSignature: Int(cdEntry.timeSignature) == 0 ? nil : Int(cdEntry.timeSignature),
            loudness: cdEntry.loudness == 0 ? nil : cdEntry.loudness,
            durationMs: Int(cdEntry.durationMs) == 0 ? nil : Int(cdEntry.durationMs)
        )
    }
    
    /// Update CDJournalEntry (Core Data) with data from JournalEntry (Swift struct)
    private func updateCDEntry(_ cdEntry: CDJournalEntry, with entry: JournalEntry) {
        // Core properties
        cdEntry.id = entry.id
        cdEntry.songId = entry.song.id
        cdEntry.songTitle = entry.song.title
        cdEntry.songArtist = entry.song.artist
        cdEntry.albumArtURL = entry.song.albumArtURL
        cdEntry.albumArtSymbol = entry.song.albumArtSymbol
        
        // Journal data
        cdEntry.journalText = entry.journalText
        cdEntry.location = entry.location
        cdEntry.latitude = entry.latitude
        cdEntry.longitude = entry.longitude
        cdEntry.date = entry.date
        
        // User metrics
        cdEntry.nostalgiaValue = entry.nostalgiaValue
        cdEntry.energyValue = entry.energyValue
        cdEntry.moodValue = entry.moodValue
        cdEntry.isLivePerformance = entry.isLivePerformance
        
        // Context
        cdEntry.activity = entry.activity
        cdEntry.company = entry.company
        
        // Spotify audio features
        cdEntry.genre = entry.genre
        cdEntry.tempo = entry.tempo ?? 0
        cdEntry.spotifyEnergy = entry.spotifyEnergy ?? 0
        cdEntry.danceability = entry.danceability ?? 0
        cdEntry.valence = entry.valence ?? 0
        cdEntry.acousticness = entry.acousticness ?? 0
        cdEntry.instrumentalness = entry.instrumentalness ?? 0
        cdEntry.liveness = entry.liveness ?? 0
        cdEntry.speechiness = entry.speechiness ?? 0
        cdEntry.key = Int16(entry.key ?? -1)
        cdEntry.mode = Int16(entry.mode ?? -1)
        cdEntry.timeSignature = Int16(entry.timeSignature ?? 0)
        cdEntry.loudness = entry.loudness ?? 0
        cdEntry.durationMs = Int32(entry.durationMs ?? 0)
    }
}
