import SwiftUI

struct CommunityView: View {
    @StateObject private var communityViewModel = CommunityViewModel()
    @StateObject private var userViewModel = UserViewModel.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingCreatePost = false
    @State private var showingCommentSheet = false
    @State private var selectedPostIdForComments: String? = nil
    
    // Tags matching the Create Post screen
    let tags = ["STRESS", "ANXIETY", "HAPPINESS", "GRATITUDE", "WORK", "RELATIONSHIPS", "MENTAL HEALTH", "AFFIRMATION", "DAILY"]
    @State private var selectedTags: Set<String> = []
    
    var body: some View {
        ZStack {
            EliteBackgroundView()
            
            // Scrollable content
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 20) {
                    if communityViewModel.posts.isEmpty && !communityViewModel.isLoading {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.square.stack")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No posts found. Be the first to share!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(communityViewModel.posts) { post in
                            CommunityPostCard(
                                postWithUser: post,
                                onLike: {
                                    Task { try? await communityViewModel.toggleLike(postId: post.id) }
                                },
                                onComment: {
                                    selectedPostIdForComments = post.id.uuidString
                                    showingCommentSheet = true
                                },
                                onShare: { sharePost(post: post) },
                                onReport: { print("Report tapped") },
                                onDelete: {
                                    Task { try? await communityViewModel.deletePost(id: post.id) }
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 120)
                .padding(.top, 20)
            }
            .safeAreaInset(edge: .top) {
                VStack(spacing: 0) {
                    headerView
                        .padding(.top, 60)
                        .padding(.bottom, 10)
                        .background(colorScheme == .dark ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color(red: 0.94, green: 0.96, blue: 1.0).opacity(0.95)))
                }
            }
            .refreshable {
                await communityViewModel.fetchPosts(refresh: true)
                await userViewModel.fetchProfile()
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .preferredColorScheme(.dark)
        .onAppear {
            // Only fetch on first load, not every tab switch
            guard communityViewModel.posts.isEmpty else { return }
            Task {
                await communityViewModel.fetchPosts()
                if userViewModel.user == nil {
                    await userViewModel.fetchProfile()
                }
            }
        }
        .sheet(isPresented: $showingCreatePost, onDismiss: {
            Task {
                await communityViewModel.fetchPosts(refresh: true)
                await userViewModel.fetchProfile()
            }
        }) {
            CreatePostView()
                .presentationCornerRadius(28)
        }
        .onChange(of: showingCommentSheet) { showing in
            // Fallback clear logic string
            if !showing {
                selectedPostIdForComments = nil
            }
        }
        .sheet(isPresented: $showingCommentSheet) {
            if let postId = selectedPostIdForComments {
                CommentSheetView(postId: postId, communityViewModel: communityViewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Profile & Plus Row
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .stroke(Color.eliteAccentPrimary.opacity(0.35), lineWidth: 2)
                        .frame(width: 50, height: 50)
                    
                    if let urlString = userViewModel.user?.profileImageUrl,
                       !urlString.isEmpty,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill().frame(width: 46, height: 46).clipShape(Circle())
                            } else {
                                fallbackAvatar
                            }
                        }
                    } else {
                        fallbackAvatar
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(userViewModel.user?.name ?? "Loading...")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("\(userViewModel.user?.totalPosts ?? 0) Total Posts")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingCreatePost = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(colorScheme == .dark ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.white), in: Circle())
                        .overlay(Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 0.5))
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.06 : 0.1), radius: 6, x: 0, y: 3)
                }
            }
            .padding(.horizontal, 20)
            
            // Filter By Tag Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Filter by Tag")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                    if !selectedTags.isEmpty {
                        Text("\(selectedTags.count) selected")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.eliteAccentPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.eliteAccentPrimary.opacity(0.15), in: Capsule())
                    }
                }
                .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // "All" clear chip
                        Button(action: {
                            if !selectedTags.isEmpty {
                                selectedTags = []
                                Task { await communityViewModel.fetchPosts(refresh: true) }
                            }
                        }) {
                            Text("ALL")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    selectedTags.isEmpty
                                        ? AnyShapeStyle(Color.eliteAccentPrimary)
                                        : AnyShapeStyle(colorScheme == .dark ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.white.opacity(0.9))),
                                    in: Capsule()
                                )
                                .overlay(Capsule().stroke(selectedTags.isEmpty ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 0.5))
                                .foregroundStyle(selectedTags.isEmpty ? Color.white : Color.primary)
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTags.isEmpty)
                        
                        ForEach(tags, id: \.self) { tag in
                            let isSelected = selectedTags.contains(tag)
                            Button(action: {
                                // Capture new state after toggle
                                var newSelection = selectedTags
                                if isSelected {
                                    newSelection.remove(tag)
                                } else {
                                    newSelection.insert(tag)
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTags = newSelection
                                }
                                Task {
                                    if newSelection.isEmpty {
                                        await communityViewModel.fetchPosts(refresh: true)
                                    } else {
                                        // Use sorted first for deterministic filter
                                        await communityViewModel.fetchPosts(page: 1, tag: newSelection.sorted().first, refresh: true)
                                    }
                                }
                            }) {
                                Text(tag)
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(
                                        isSelected
                                            ? AnyShapeStyle(Color.eliteAccentPrimary)
                                            : AnyShapeStyle(colorScheme == .dark ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.white.opacity(0.9))),
                                        in: Capsule()
                                    )
                                    .overlay(Capsule().stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 0.5))
                                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.06 : 0.08), radius: 5, x: 0, y: 2)
                                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                                    .scaleEffect(isSelected ? 1.04 : 1.0)
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private var fallbackAvatar: some View {
        Circle()
            .fill(Color.eliteAccentPrimary.opacity(0.15))
            .frame(width: 46, height: 46)
            .overlay(
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.eliteAccentPrimary.opacity(0.6))
            )
    }
    
    private func sharePost(post: CommunityViewModel.CommunityPostWithUser) {
        let text = "Check out this inspiring post on Rewind: \(post.post.content)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first { $0.isKeyWindow }
        
        if let root = window?.rootViewController {
            root.present(activityVC, animated: true, completion: nil)
        }
    }
}
