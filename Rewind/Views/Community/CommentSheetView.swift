import SwiftUI

struct CommentSheetView: View {
    let postId: String
    @ObservedObject var communityViewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var commentText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var commentToDelete: CommunityViewModel.CommentWithUser?
    @State private var showDeleteConfirm: Bool = false
    @State private var reportingComment: CommunityViewModel.CommentWithUser?
    @State private var reportBannerMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                EliteBackgroundView()
                
                VStack(spacing: 0) {
                    // Comments List
                    if communityViewModel.isLoading && communityViewModel.comments.isEmpty {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Spacer()
                    } else if communityViewModel.comments.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No comments yet. Be the first to comment!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(communityViewModel.comments) { comment in
                                    CommentRowView(
                                        commentItem: comment,
                                        postId: postId,
                                        onDelete: {
                                            commentToDelete = comment
                                            showDeleteConfirm = true
                                        },
                                        onReport: {
                                            reportingComment = comment
                                        }
                                    )
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Input Bar
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color.secondary.opacity(0.2))
                        
                        HStack(alignment: .bottom, spacing: 12) {
                            TextField("Add a comment...", text: $commentText, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(1...5)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                                )
                            
                            Button(action: submitComment) {
                                Group {
                                    if isSubmitting {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .background(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.5) : Color.eliteAccentPrimary, in: Circle())
                            }
                            .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .padding(.bottom, 8) // SafeArea buffer
                        .background(.ultraThinMaterial)
                    }
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary, .ultraThinMaterial)
                            .font(.system(size: 28))
                    }
                    .padding(.top, 8)
                }
            }
            .alert("Error", isPresented: $showError, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMessage)
            })
            .alert("Delete Comment?", isPresented: $showDeleteConfirm, actions: {
                Button("Delete", role: .destructive) {
                    guard let comment = commentToDelete,
                          let postUUID = UUID(uuidString: postId) else { return }
                    Task {
                        do {
                            try await communityViewModel.deleteComment(
                                commentId: comment.id,
                                postId: postUUID
                            )
                        } catch {
                            await MainActor.run {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                }
                Button("Cancel", role: .cancel) { commentToDelete = nil }
            }, message: {
                Text("This will permanently remove your comment.")
            })
            .onAppear {
                if let uuid = UUID(uuidString: postId) {
                    Task {
                        await communityViewModel.fetchComments(postId: uuid)
                    }
                }
            }
            .sheet(item: $reportingComment) { comment in
                ReportContentSheet(type: .comment) { reason, details in
                    Task {
                        do {
                            try await communityViewModel.reportComment(
                                commentId: comment.id,
                                reason: reason
                            )
                            await MainActor.run {
                                reportBannerMessage = "Thanks. Your report has been submitted."
                                reportingComment = nil
                            }
                        } catch {
                            await MainActor.run {
                                reportBannerMessage = error.localizedDescription
                                reportingComment = nil
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
            }
            .alert("Report", isPresented: .init(
                get: { reportBannerMessage != nil },
                set: { if !$0 { reportBannerMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(reportBannerMessage ?? "")
            }
        }
    }
    
    private func submitComment() {
        guard let uuid = UUID(uuidString: postId) else { return }
        let textToSend = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToSend.isEmpty else { return }

        // Block submission if comment contains objectionable language
        if ContentFilter.containsObjectionableContent(text: textToSend) {
            errorMessage = "Your comment contains language that violates our community guidelines. Please revise it before posting."
            showError = true
            return
        }

        isSubmitting = true
        Task {
            do {
                _ = try await communityViewModel.addComment(postId: uuid, text: textToSend)
                await MainActor.run {
                    self.commentText = ""
                    self.isSubmitting = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isSubmitting = false
                }
            }
        }
    }
}

struct CommentRowView: View {
    let commentItem: CommunityViewModel.CommentWithUser
    let postId: String
    let onDelete: () -> Void
    let onReport: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            if let user = commentItem.user {
                if let imageUrl = user.profileImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            fallbackAvatar
                        case .success(let image):
                            image.resizable().scaledToFill().frame(width: 36, height: 36).clipShape(Circle())
                        case .failure:
                            fallbackAvatar
                        @unknown default:
                            fallbackAvatar
                        }
                    }
                } else {
                    fallbackAvatar
                }
            } else {
                fallbackAvatar
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(commentItem.user?.name ?? "Anonymous")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(timeAgo(from: commentItem.comment.createdAt))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.secondary)
                    
                    Menu {
                        if commentItem.isMine {
                            Button(role: .destructive, action: onDelete) {
                                Label("Delete", systemImage: "trash")
                            }
                        } else {
                            Button(role: .destructive, action: onReport) {
                                Label("Report", systemImage: "flag")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                Text(commentItem.comment.content)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
        )
    }
    
    private var fallbackAvatar: some View {
        Circle()
            .fill(Color.eliteAccentPrimary.opacity(0.15))
            .frame(width: 36, height: 36)
            .overlay(
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.eliteAccentPrimary)
            )
    }
    
    private func timeAgo(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        // Try with fractional seconds first
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString) else {
            return "Just now"
        }
        
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}
