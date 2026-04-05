import SwiftUI

struct CommunityPostCard: View {
    let postWithUser: CommunityViewModel.CommunityPostWithUser
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    let onReport: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackground: some ShapeStyle {
        colorScheme == .dark ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.white)
    }
    
    private var cardBorderColor: Color {
        colorScheme == .dark ? Color.secondary.opacity(0.2) : Color.black.opacity(0.08)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: User Info & Menu
            HStack(spacing: 12) {
                // Avatar
                if postWithUser.post.isAnonymous {
                    Circle()
                        .fill(Color.eliteAccentPrimary.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.eliteAccentPrimary)
                        )
                } else if let imageUrl = postWithUser.user?.profileImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Circle().fill(Color.eliteAccentPrimary.opacity(0.15)).frame(width: 44, height: 44)
                        case .success(let image):
                            image.resizable().scaledToFill().frame(width: 44, height: 44).clipShape(Circle())
                        case .failure:
                            fallbackAvatar
                        @unknown default:
                            fallbackAvatar
                        }
                    }
                } else {
                    fallbackAvatar
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(postWithUser.post.isAnonymous ? "Anonymous" : (postWithUser.user?.name ?? "Unknown"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(timeAgo(from: postWithUser.post.createdAt))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Menu {
                    if postWithUser.isMine {
                        Button("Edit Post") {
                            onEdit()
                        }

                        Button("Delete Post", role: .destructive) {
                            onDelete()
                        }
                    } else {
                        Button("Report Post", role: .destructive) {
                            onReport()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 48, height: 48)
                        .contentShape(Rectangle())
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .zIndex(5)
            }
            
            // Post Content
            Text(postWithUser.post.content)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
            // Media Preview (if available)
            if let firstMediaUrlString = postWithUser.post.mediaUrls.first,
               !firstMediaUrlString.isEmpty {
                PostMediaView(urlString: firstMediaUrlString)
                .overlay(
                    Group {
                        if postWithUser.post.mediaUrls.count > 1 {
                            Text("+\(postWithUser.post.mediaUrls.count - 1)")
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.thinMaterial, in: Capsule())
                                .padding(12)
                        }
                    },
                    alignment: .bottomTrailing
                )
            }
            
            // Divider
            Divider()
                .padding(.vertical, 4)
            
            // Actions Row
            HStack(spacing: 24) {
                // Like Button
                actionButton(
                    icon: postWithUser.isLiked ? "heart.fill" : "heart",
                    iconColor: postWithUser.isLiked ? .red : .primary,
                    count: postWithUser.post.likeCount,
                    action: onLike
                )
                
                // Comment Button
                actionButton(
                    icon: "bubble.left.and.bubble.right",
                    iconColor: .primary,
                    count: postWithUser.post.commentCount,
                    action: onComment
                )
                
                Spacer()
                
                // Share Button
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(colorScheme == .dark ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.white),
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(cardBorderColor, lineWidth: colorScheme == .dark ? 0.5 : 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.08 : 0.1), radius: 12, x: 0, y: 6)
    }
    
    private var fallbackAvatar: some View {
        Circle()
            .fill(Color.eliteAccentPrimary.opacity(0.15))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.eliteAccentPrimary)
            )
    }
    
    private func actionButton(icon: String, iconColor: Color, count: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(iconColor)
                Text("\(count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

struct PostMediaView: View {
    let urlString: String
    
    var body: some View {
        Group {
            if urlString.hasPrefix("http"), let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else if phase.error != nil {
                        placeholder
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(maxWidth: .infinity, idealHeight: 200)
                            .overlay(ProgressView())
                    }
                }
            } else {
                placeholder
            }
        }
    }
    
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.secondary.opacity(0.1))
            .frame(maxWidth: .infinity, idealHeight: 200)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
            )
    }
}
