// MARK: - File Header
//
// CalendarView.swift
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
import MapKit

/// Displays BeatMap journal entries on a graphical calendar.
/// Users can browse entries by date and see all musical moments from specific days.
struct CalendarView: View {
    
    // MARK: - Environment & State
    
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedDate: Date? = .now
    
    // MARK: - Computed Properties
    
    /// Groups journal entries by day for efficient lookup
    private var entriesByDate: [Date: [JournalEntry]] {
        Dictionary(grouping: journalStore.entries, by: {
            Calendar.current.startOfDay(for: $0.date)
        })
    }
    
    /// Returns all entries for the currently selected date
    private var selectedDateEntries: [JournalEntry] {
        guard let date = selectedDate else { return [] }
        let startOfDay = Calendar.current.startOfDay(for: date)
        return entriesByDate[startOfDay] ?? []
    }

    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack {
                // Calendar picker
                DatePicker(
                    "Select a Date",
                    selection: Binding(
                        get: { selectedDate ?? .now },
                        set: { selectedDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .accentColor(themeManager.currentTheme.accentColor)
                .frame(maxWidth: 400)
                
                // Selected date content
                VStack {
                    // Date header
                    Text(selectedDate?.formatted(date: .complete, time: .omitted) ?? "Select a Date")
                        .font(.headline)
                        .padding(.vertical, 15)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Divider()
                    
                    // Entries or empty state
                    if selectedDateEntries.isEmpty {
                        VStack(spacing: 15) {
                            Spacer(minLength: 50)
                            Image(systemName: "music.note.slash")
                                .font(.system(size: 40))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            Text("No Entries")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("No journal entries for this day")
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        
                    } else {
                        // Entry list with proper sizing
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(selectedDateEntries) { entry in
                                    NavigationLink(destination: JournalDetailView(entry: entry)) {
                                        JournalEntryRowView(entry: entry)
                                            .padding()
                                            .background(themeManager.currentTheme.secondaryBackgroundColor)
                                            .cornerRadius(10)
                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }
}

#Preview {
    PreviewContainer {
        CalendarView()
    }
}
