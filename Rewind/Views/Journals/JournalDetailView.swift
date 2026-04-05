import SwiftUI
import AVFoundation

struct JournalDetailView: View {
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let journal: DBJournal
    let onDeleteCompleted: (() -> Void)?

    init(journal: DBJournal, onDeleteCompleted: (() -> Void)? = nil) {
        self.journal = journal
        self.onDeleteCompleted = onDeleteCompleted
    }
    @State private var isEditing = false
    @State private var editTitle = ""
    @State private var editContent = ""
    @State private var editEmotion = ""
    @State private var isLoading = false
    @State private var showDeleteConfirmation = false
    @State private var showModernEditor = false
    @State private var localJournal: DBJournal?
    @State private var audioPlayer: AVPlayer?
    @State private var isAudioPlaying = false
    @State private var showImageViewer = false

    private var displayJournal: DBJournal {
        localJournal ?? journal
    }

    private var displayFeelings: [String] {
        (displayJournal.feelings ?? []).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var displayActivities: [String] {
        (displayJournal.activities ?? []).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var displayTags: [String] {
        let feelingSet = Set(displayFeelings.map { $0.lowercased() })
        let activitySet = Set(displayActivities.map { $0.lowercased() })

        return displayJournal.tags.filter {
            let normalized = $0.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty else { return false }
            let lowered = normalized.lowercased()
            return !feelingSet.contains(lowered) && !activitySet.contains(lowered)
        }
    }

    private var voiceAudioURL: URL? {
        if let raw = displayJournal.voiceRecordingUrl,
           !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return resolvedURL(from: raw)
        }

        return displayJournal.mediaUrls.compactMap { resolvedURL(from: $0) }
            .first(where: { isLikelyAudioURL($0) })
    }

    private var displayImageURLs: [URL] {
        displayJournal.mediaUrls.compactMap { raw in
            guard let url = resolvedURL(from: raw), !isLikelyAudioURL(url) else {
                return nil
            }
            return url
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            EliteBackgroundView()
            
            VStack(spacing: 0) {
                // Simple header with just menu
                HStack {
                    Spacer()
                    
                    Menu {
                        if !isEditing {
                            Button {
                                showModernEditor = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        readingContent
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                }
            }
        }
        .alert("Delete Entry?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task { await deleteJournal() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .fullScreenCover(isPresented: $showModernEditor) {
            AddJournalView(journalToEdit: displayJournal) { updatedJournal in
                localJournal = updatedJournal
                onDeleteCompleted?()
            }
        }
        .onAppear {
            editTitle = displayJournal.title
            editContent = displayJournal.content
            editEmotion = displayJournal.emotion ?? ""
        }
        .onDisappear {
            audioPlayer?.pause()
            isAudioPlaying = false
        }
        .navigationBarBackButtonHidden(false)
    }
    
    // MARK: - Reading View
    
    private var readingContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title & Metadata
            VStack(alignment: .leading, spacing: 16) {
                Text(displayJournal.title.isEmpty ? "Untitled Entry" : displayJournal.title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ENTRY DATE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                        
                        Text(formattedDate(displayJournal.createdDate))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    if let emotion = displayJournal.emotion, !emotion.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "smiley.fill")
                                .font(.system(size: 16))
                            Text(emotion.capitalized)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.eliteAccentSecondary)
                        .cornerRadius(10)
                    }
                }
            }
            
            // Content Card
            VStack(alignment: .leading, spacing: 0) {
                Text(displayJournal.content.isEmpty ? "No content" : displayJournal.content)
                    .font(.system(size: 17, weight: .regular, design: .default))
                    .foregroundStyle(.primary)
                    .lineSpacing(6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.eliteSurface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.eliteBorder.opacity(0.5), lineWidth: 1)
            )

            if !displayFeelings.isEmpty {
                metadataSection(title: "Feelings", items: displayFeelings)
            }

            if !displayActivities.isEmpty {
                metadataSection(title: "Activities", items: displayActivities)
            }

            if !displayTags.isEmpty {
                metadataSection(title: "Tags", items: displayTags)
            }

            if let audioURL = voiceAudioURL {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Audio")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Button {
                        toggleAudioPlayback(with: audioURL)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: isAudioPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text(isAudioPlaying ? "Pause Recording" : "Play Recording")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.eliteSurface)
                        .cornerRadius(10)
                    }
                }
            }

            if !displayImageURLs.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Media")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(displayImageURLs, id: \.absoluteString) { url in
                                Button(action: { showImageViewer = true }) {
                                    if url.isFileURL, let image = UIImage(contentsOfFile: url.path) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 96, height: 96)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.eliteSurface)
                                                ProgressView()
                                            }
                                        }
                                        .frame(width: 96, height: 96)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .fullScreenCover(isPresented: $showImageViewer) {
                        ImageViewerView(imageURLs: displayImageURLs)
                    }
                }
            }
        }
    }

    private func metadataSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.eliteSurface)
                        .cornerRadius(10)
                }
            }
        }
    }

    private func resolvedURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }

        return URL(fileURLWithPath: trimmed)
    }

    private func isLikelyAudioURL(_ url: URL) -> Bool {
        let pathExt = url.pathExtension.lowercased()
        return ["m4a", "mp3", "wav", "aac", "caf"].contains(pathExt)
    }

    private func toggleAudioPlayback(with url: URL) {
        if isAudioPlaying {
            audioPlayer?.pause()
            isAudioPlaying = false
            return
        }

        if audioPlayer == nil || (audioPlayer?.currentItem?.asset as? AVURLAsset)?.url != url {
            audioPlayer = AVPlayer(url: url)
        }

        audioPlayer?.play()
        isAudioPlaying = true
    }
    
    // MARK: - Editing View
    
    private var editingContent: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Entry Date & Time")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(formattedDateTime(journal.createdDate))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.eliteSurface)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.eliteBorder.opacity(0.5), lineWidth: 1)
                    )
            }

            // Title Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                TextField(
                    "Entry title",
                    text: $editTitle
                )
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.primary)
                .padding(14)
                .background(Color.eliteSurface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.eliteBorder.opacity(0.5), lineWidth: 1)
                )
            }
            
            // Content Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Entry")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $editContent)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.primary)
                    .padding(14)
                    .frame(minHeight: 200)
                    .background(Color.eliteSurface)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.eliteBorder.opacity(0.5), lineWidth: 1)
                    )
            }
            
            // Emotion Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("How are you feeling?")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                let emotions = ["happy", "sad", "excited", "thoughtful", "calm", "stressed"]
                
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(Array(emotions.prefix(3)), id: \.self) { emotion in
                            emotionButton(emotion: emotion, isSelected: editEmotion == emotion)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(Array(emotions.dropFirst(3)), id: \.self) { emotion in
                            emotionButton(emotion: emotion, isSelected: editEmotion == emotion)
                        }
                        Spacer()
                    }
                }
            }

            if !displayFeelings.isEmpty {
                metadataSection(title: "Feelings", items: displayFeelings)
            }

            if !displayActivities.isEmpty {
                metadataSection(title: "Activities", items: displayActivities)
            }

            if !displayTags.isEmpty {
                metadataSection(title: "Tags", items: displayTags)
            }
        }
    }
    
    // MARK: - Emotion Button
    
    private func emotionButton(emotion: String, isSelected: Bool) -> some View {
        Button(action: {
            editEmotion = isSelected ? "" : emotion
        }) {
            Text(emotion.capitalized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isSelected ? Color.eliteAccentSecondary : Color.eliteSurface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSelected ? Color.clear : Color.eliteBorder.opacity(0.5),
                            lineWidth: 1
                        )
                )
        }
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        isLoading = true
        
        Task {
            do {
                try await viewModel.updateJournal(
                    id: journal.id,
                    title: editTitle,
                    content: editContent,
                    emotion: editEmotion.isEmpty ? nil : editEmotion
                )
                
                await MainActor.run {
                    isEditing = false
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    viewModel.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func deleteJournal() async {
        do {
            try await viewModel.deleteJournal(id: journal.id)
            await MainActor.run {
                onDeleteCompleted?()
                dismiss()
            }
        } catch {
            await MainActor.run {
                viewModel.error = error.localizedDescription
            }
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
        dateFormatter.dateFormat = "MMM d, yyyy"
        return "\(dateFormatter.string(from: date)) • \(timeFormatter.string(from: date))"
    }
    
    private func formattedDateTime(_ date: Date?) -> String {
        guard let date else { return "Unknown date" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy • h:mm a"
        return formatter.string(from: date)
    }
}


#Preview {
    JournalDetailView(
        journal: DBJournal(
            id: UUID(),
            userId: UUID(),
            title: "My First Entry",
            content: "Today was a great day. I had a wonderful time with friends.",
            emotion: "happy",
            tags: ["friends", "happy"],
            mediaUrls: [],
            isFavorite: false,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    )
}
