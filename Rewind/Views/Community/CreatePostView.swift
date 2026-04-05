//
//  CreatePostView.swift
//  Rewind
//

import SwiftUI
import PhotosUI
import Supabase

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // ViewModels
    @StateObject private var communityViewModel = CommunityViewModel()
    @ObservedObject private var userViewModel: UserViewModel = .shared

    // Form state
    @State private var postText: String = ""
    @State private var isAnonymous: Bool = false
    @State private var selectedTags: Set<String> = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []

    // UI state
    @State private var isPosting: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @FocusState private var isTextFocused: Bool

    private let availableTags = ["STRESS", "ANXIETY", "HAPPINESS", "GRATITUDE", "WORK", "RELATIONSHIPS", "MENTAL HEALTH", "AFFIRMATION", "DAILY"]

    private var canPost: Bool {
        !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isPosting
    }

    var body: some View {
        ZStack {
            EliteBackgroundView()

            VStack(spacing: 0) {
                // Header
                headerBar
                    .padding(.top, 4)

                Divider()
                    .opacity(0.3)

                // Scrollable Form
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        // Profile Row
                        profileSection

                        // Text Input
                        textInputSection

                        // Tags
                        tagsSection

                        // Media
                        mediaSection

                        // Anonymous Toggle
                        anonymousSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            if userViewModel.user == nil {
                Task { await userViewModel.fetchProfile() }
            }
        }
        .alert("Couldn't Post", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 0) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 38, height: 38)
                    .background(.regularMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.secondary.opacity(0.18), lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Create Post")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.primary)

            Spacer()

            Button(action: submitPost) {
                Group {
                    if isPosting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                            .frame(width: 60)
                    } else {
                        Text("Post")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                    }
                }
                .frame(height: 38)
                .background(canPost ? Color.eliteAccentPrimary : Color.eliteAccentPrimary.opacity(0.35), in: Capsule())
                .shadow(color: Color.eliteAccentPrimary.opacity(canPost ? 0.35 : 0), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(!canPost)
            .animation(.easeOut(duration: 0.2), value: canPost)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.eliteAccentPrimary.opacity(0.15))
                    .frame(width: 48, height: 48)

                if isAnonymous {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.eliteAccentPrimary.opacity(0.6))
                } else if let urlStr = userViewModel.user?.profileImageUrl,
                          !urlStr.isEmpty, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if let img = phase.image {
                            img.resizable().scaledToFill()
                                .frame(width: 48, height: 48).clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(Color.eliteAccentPrimary.opacity(0.6))
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.eliteAccentPrimary.opacity(0.6))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isAnonymous ? "Anonymous" : (userViewModel.user?.name ?? "Loading..."))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .animation(.easeOut(duration: 0.2), value: isAnonymous)

                Label(isAnonymous ? "Hidden identity" : "Public post",
                      systemImage: isAnonymous ? "eye.slash" : "globe")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .animation(.easeOut(duration: 0.2), value: isAnonymous)
            }

            Spacer()
        }
    }

    // MARK: - Text Input

    private var textInputSection: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if postText.isEmpty {
                Text("What's on your mind? Share your thoughts...")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                    .padding(.top, 8)
                    .padding(.leading, 4)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $postText)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.primary)
                .frame(minHeight: 140, alignment: .top)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isTextFocused)
                .tint(Color.eliteAccentPrimary)
        }
        .padding(16)
        .background(
            colorScheme == .dark
                ? AnyShapeStyle(.regularMaterial)
                : AnyShapeStyle(Color.white.opacity(0.85)),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isTextFocused ? Color.eliteAccentPrimary.opacity(0.5) : Color.secondary.opacity(0.15),
                    lineWidth: isTextFocused ? 1.5 : 0.5
                )
        )
        .animation(.easeOut(duration: 0.2), value: isTextFocused)
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.eliteAccentPrimary)

                Text("Tags")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)

                if !selectedTags.isEmpty {
                    Text("\(selectedTags.count) selected")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.eliteAccentPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.eliteAccentPrimary.opacity(0.12), in: Capsule())
                        .transition(.scale.combined(with: .opacity))
                }
            }

            // Wrapping chip layout using FlowLayout
            TagFlowLayout(tags: availableTags, selectedTags: $selectedTags)
        }
    }

    // MARK: - Media Section

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.eliteAccentPrimary)

                Text("Media")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                if !selectedImages.isEmpty {
                    Text("\(selectedImages.count)/4")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Existing images
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            // Remove button
                            Button(action: { selectedImages.remove(at: index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white)
                                    .background(Color.black.opacity(0.5), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .offset(x: 6, y: -6)
                        }
                    }

                    // Add button (if < 4 images)
                    if selectedImages.count < 4 {
                        PhotosPicker(
                            selection: $selectedItems,
                            maxSelectionCount: 4 - selectedImages.count,
                            matching: .images
                        ) {
                            VStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(Color.eliteAccentPrimary)
                                Text("Add Photo")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 90, height: 90)
                            .background(
                                colorScheme == .dark
                                    ? AnyShapeStyle(.regularMaterial)
                                    : AnyShapeStyle(Color.white.opacity(0.85)),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(
                                        Color.eliteAccentPrimary.opacity(0.3),
                                        style: StrokeStyle(lineWidth: 1.5, dash: [5])
                                    )
                            )
                        }
                        .onChange(of: selectedItems) { items in
                            Task { await loadImages(from: items) }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Anonymous Toggle

    private var anonymousSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.eliteAccentPrimary.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.eliteAccentPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Post Anonymously")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Your name will be hidden")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isAnonymous)
                .labelsHidden()
                .tint(Color.eliteAccentPrimary)
        }
        .padding(16)
        .background(
            colorScheme == .dark
                ? AnyShapeStyle(.regularMaterial)
                : AnyShapeStyle(Color.white.opacity(0.85)),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 0.5)
        )
    }

    // MARK: - Actions

    private func submitPost() {
        let content = postText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        isPosting = true

        Task {
            var mediaUrls: [String] = []

            // Upload images
            if !selectedImages.isEmpty {
                let bucket = SupabaseConfig.shared.client.storage.from("community-media")
                let session = try? await SupabaseConfig.shared.client.auth.session
                let userIdStr = session?.user.id.uuidString.lowercased() ?? UUID().uuidString.lowercased()

                for image in selectedImages {
                    if let data = image.jpegData(compressionQuality: 0.8) {
                        let filename = "\(userIdStr)/\(UUID().uuidString.lowercased()).jpg"
                        do {
                            try await bucket.upload(
                                path: filename,
                                file: data,
                                options: SupabaseConfig.Client.UploadOptions(contentType: "image/jpeg")
                            )
                            let publicUrl = try bucket.getPublicURL(path: filename).absoluteString
                            mediaUrls.append(publicUrl)
                        } catch {
                            print("Error uploading image: \(error)")
                        }
                    }
                }
            }

            do {
                _ = try await communityViewModel.createPost(
                    content: content,
                    isAnonymous: isAnonymous,
                    tags: Array(selectedTags),
                    mediaUrls: mediaUrls
                )
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("CommunityPostDeleted"), object: nil)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isPosting = false
                }
            }
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    if selectedImages.count < 4 {
                        selectedImages.append(image)
                    }
                }
            }
        }
        await MainActor.run { selectedItems = [] }
    }
}

// MARK: - Wrapping Tag Flow Layout

/// A wrapping chip grid using SwiftUI's Layout protocol (iOS 16+).
struct TagFlowLayout: View {
    let tags: [String]
    @Binding var selectedTags: Set<String>
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ChipFlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                chipView(for: tag)
            }
        }
    }

    private func chipView(for tag: String) -> some View {
        let isSelected = selectedTags.contains(tag)
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
            }
        }) {
            Text(tag)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? AnyShapeStyle(Color.eliteAccentPrimary)
                        : AnyShapeStyle(colorScheme == .dark ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.white.opacity(0.85))),
                    in: Capsule()
                )
                .overlay(Capsule().stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 0.5))
                .shadow(color: isSelected ? Color.eliteAccentPrimary.opacity(0.3) : Color.black.opacity(0.05),
                        radius: isSelected ? 6 : 3, x: 0, y: isSelected ? 3 : 1)
                .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

/// Custom Layout conformance for flowing/wrapping chip rows.
struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > containerWidth, rowWidth > 0 {
                height += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: containerWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
