import SwiftUI
import AVKit

struct JournalsView: View {
    @StateObject private var journalViewModel = JournalViewModel()
    @State private var showAddJournal = false
    @State private var selectedJournal: DBJournal?
    @State private var showSelectedJournal = false
    @Environment(\.colorScheme) private var colorScheme
    
    let onJournalTapped: ((DBJournal) -> Void)?
    
    init(onJournalTapped: ((DBJournal) -> Void)? = nil) {
        self.onJournalTapped = onJournalTapped
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                EliteBackgroundView()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                    
                    // Content
                    if journalViewModel.journals.isEmpty {
                        emptyStateView
                            .frame(maxHeight: .infinity)
                    } else {
                        journalListView
                    }
                }
                
                // FAB
                fabView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(24)
                
                // Navigation
                NavigationLink(
                    destination: JournalDetailView(
                        journal: selectedJournal ?? journalViewModel.journals.first ?? DBJournal(
                            id: UUID(),
                            userId: UUID(),
                            title: "",
                            content: "",
                            emotion: "",
                            tags: [],
                            mediaUrls: [],
                            isFavorite: false,
                            createdAt: "",
                            updatedAt: ""
                        ),
                        onDeleteCompleted: {
                            Task {
                                await journalViewModel.fetchAllJournals(refresh: true)
                            }
                        }
                    ),
                    isActive: $showSelectedJournal
                ) {
                    EmptyView()
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showAddJournal) {
                AddJournalView()
                    .environmentObject(journalViewModel)
                    .onDisappear {
                        Task {
                            await journalViewModel.fetchAllJournals(refresh: true)
                        }
                    }
            }
        }
        .task {
            await journalViewModel.fetchAllJournals(refresh: true)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My Journals")
                .font(.system(size: 34, weight: .bold, design: .default))
                .foregroundStyle(.primary)
            
            Text("\(journalViewModel.journals.count) entries • Latest first")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(.secondary)
            
            Text("No journals yet")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("Tap the + button to create your first entry")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Journal List
    
    private var journalListView: some View {
        let sorted = journalViewModel.journals.sorted {
            ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast)
        }
        
        return ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(sorted, id: \.id) { journal in
                    journalRowView(journal)
                        .onTapGesture {
                            selectedJournal = journal
                            if onJournalTapped != nil {
                                onJournalTapped?(journal)
                            } else {
                                showSelectedJournal = true
                            }
                        }
                }
            }
            .padding(16)
        }
        .refreshable {
            await journalViewModel.fetchAllJournals(refresh: true)
        }
    }
    
    // MARK: - Journal Row
    
    private func journalRowView(_ journal: DBJournal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date & Mood
            HStack(spacing: 12) {
                Text(formattedDate(journal.createdDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let emotion = journal.emotion, !emotion.isEmpty {
                    Text(emotion.capitalized)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.eliteAccentSecondary)
                        .cornerRadius(8)
                }
            }
            
            // Title
            Text((journal.title ?? "").isEmpty ? "Untitled Entry" : journal.title ?? "Untitled Entry")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
            
            // Preview
            Text((journal.content ?? "").isEmpty ? "No content" : journal.content ?? "No content")
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.eliteBorder.opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - FAB
    
    private var fabView: some View {
        Button(action: { showAddJournal = true }) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.eliteAccentSecondary)
                .clipShape(Circle())
                .shadow(color: Color.eliteAccentSecondary.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Helpers
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "Unknown date" }
        
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        if calendar.isDateInToday(date) {
            return "Today • \(timeFormatter.string(from: date))"
        }
        
        if calendar.isDateInYesterday(date) {
            return "Yesterday • \(timeFormatter.string(from: date))"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return "\(dateFormatter.string(from: date)) • \(timeFormatter.string(from: date))"
    }
}

