// MARK: - File Header
//
// HomeView.swift
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

// MARK: - Journal Prompts

let sampleJournalPrompts = [
    "What song reminds you of your best friend?",
    "Journal about a song that always makes you dance.",
    "Describe a memory triggered by a song you heard today.",
    "What's a song that feels like a warm hug?",
    "If your current mood had a soundtrack, what song would it be?"
]

struct HomeView: View {

    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var shazamManager: ShazamManager

    @State private var sheetDetail: SheetDetail? = nil
    @State private var dynamicContent: DynamicContentType?
    @State private var shazamError: String? = nil

    enum SheetDetail: Identifiable, Hashable {
        case newEntry(Song?)
        var id: Int { self.hashValue }
    }

    enum DynamicContentType {
        case onThisDay(JournalEntry)
        case prompt(String)
    }

    var body: some View {
        NavigationView { homeContent }
        .navigationViewStyle(.stack)
    }

    private var homeContent: some View {
        ZStack {
            themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 25) {
                Text("Welcome to BeatMap")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding([.horizontal, .top])
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)

                CurrentlyPlayingWidget(onJournalTap: { song in
                    sheetDetail = .newEntry(song)
                })
                .padding(.horizontal)

                actionButtons

                if let content = dynamicContent {
                    switch content {
                    case .onThisDay(let entry):
                        OnThisDayView(entry: entry).padding(.horizontal)
                    case .prompt(let prompt):
                        JournalPromptView(prompt: prompt).padding(.horizontal)
                    }
                }

                if !journalStore.entries.isEmpty {
                    RecentEntriesCarouselView(entries: Array(journalStore.entries.prefix(5)))
                } else {
                    Text("Your recent entries will appear here.")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if shazamManager.shazamState == .listening {
                ListeningView()
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $sheetDetail) { detail in
            if case .newEntry(let song) = detail {
                NewEntryView(preselectedSong: song)
            }
        }
        .onChange(of: shazamManager.shazamState) { _, newState in
            switch newState {
            case .match:
                print("✅ Shazam match found!")
                sheetDetail = .newEntry(shazamManager.identifiedSong)
                shazamManager.shazamState = .idle
            case .noMatch:
                print("❌ Shazam: No match found")
                shazamError = "No match found. Try again in a quieter environment."
                shazamManager.shazamState = .idle
            case .error(let message):
                print("❌ Shazam error: \(message)")
                shazamError = message
                shazamManager.shazamState = .idle
            default:
                break
            }
        }
        .alert("Shazam Error", isPresented: .constant(shazamError != nil), actions: {
            Button("OK") { shazamError = nil }
        }, message: {
            Text(shazamError ?? "An unknown error occurred.")
        })
        .onAppear(perform: determineDynamicContent)
    }

    private var actionButtons: some View {
        VStack(spacing: 15) {
            Button(action: { sheetDetail = .newEntry(nil) }) {
                Text("+ Create a New Entry")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.currentTheme.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Button(action: shazamManager.startListening) {
                HStack {
                    Image(systemName: "shazam.logo.fill")
                    Text("Identify Song")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeManager.currentTheme.secondaryBackgroundColor)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }

    struct ListeningView: View {
        @EnvironmentObject var themeManager: ThemeManager
        @EnvironmentObject var shazamManager: ShazamManager
        @State private var scale: CGFloat = 1.0

        var body: some View {
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        shazamManager.stopListening()
                    }
                
                VStack(spacing: 20) {
                    Image(systemName: "shazam.logo.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .scaleEffect(scale)
                        .onAppear {
                            let animation = Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                            withAnimation(animation) { scale = 1.2 }
                        }
                    
                    Text("Listening...")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Button("Cancel") {
                        shazamManager.stopListening()
                    }
                    .tint(.white)
                    .buttonStyle(.bordered)
                }
            }
            .transition(.opacity.animation(.easeInOut))
        }
    }

    private func determineDynamicContent() {
        if let entry = findOnThisDayEntry() {
            dynamicContent = .onThisDay(entry)
        } else if let prompt = sampleJournalPrompts.randomElement() {
            dynamicContent = .prompt(prompt)
        } else {
            dynamicContent = nil
        }
    }

    private func findOnThisDayEntry() -> JournalEntry? {
        let calendar = Calendar.current
        let today = Date()
        let todayComponents = calendar.dateComponents([.month, .day, .year], from: today)

        return journalStore.entries.first { entry in
            let entryComponents = calendar.dateComponents([.month, .day, .year], from: entry.date)
            
            return entryComponents.month == todayComponents.month &&
                   entryComponents.day == todayComponents.day &&
                   entryComponents.year != todayComponents.year
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(JournalStore())
        .environmentObject(ThemeManager())
        .environmentObject(ShazamManager())
}
