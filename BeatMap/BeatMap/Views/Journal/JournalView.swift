// MARK: - File Header
//
// JournalView.swift
// BeatMap
//
// Version: 1.0.0
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI

/// Main journal browsing view for BeatMap.
/// Displays all entries in either list or calendar format with search functionality.
struct JournalView: View {
    
    // MARK: - Environment & State
    
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedView: JournalViewType = .list
    @State private var searchText = ""

    enum JournalViewType: String, CaseIterable {
        case list = "List"
        case calendar = "Calendar"
    }
    
    // MARK: - Computed Properties
    
    /// Filters entries based on search text
    var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return journalStore.entries
        } else {
            return journalStore.entries.filter {
                $0.song.title.localizedCaseInsensitiveContains(searchText) ||
                $0.song.artist.localizedCaseInsensitiveContains(searchText) ||
                $0.journalText.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        #if os(iOS)
        NavigationView {
            journalContent
        }
        .navigationViewStyle(.stack)
        #else
        journalContent
            .searchable(text: $searchText, prompt: "Search by song, artist, or keyword...")
            .navigationTitle("Journal")
        #endif
    }
    
    private var journalContent: some View {
        ZStack {
            themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea()
            
            VStack {
                // View type picker (List or Calendar)
                Picker("View Type", selection: $selectedView) {
                    ForEach(JournalViewType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])
                
                if selectedView == .list {
                    // List view with card-style entries
                    List {
                        ForEach(filteredEntries) { entry in
                            NavigationLink(destination: JournalDetailView(entry: entry)) {
                                JournalEntryRowView(entry: entry)
                                    .padding()
                            }
                            .listRowBackground(
                                themeManager.currentTheme.secondaryBackgroundColor
                                    .cornerRadius(10)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    .padding(.vertical, 4)
                            )
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: journalStore.delete)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    #if os(iOS)
                    .searchable(text: $searchText, prompt: "Search by song, artist, or keyword...")
                    #endif
                } else {
                    // Calendar view
                    CalendarView()
                        .padding(.top)
                }
            }
            .navigationTitle("Journal")
        }
    }
}

#Preview {
    PreviewContainer {
        JournalView()
    }
}
