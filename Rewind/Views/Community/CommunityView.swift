import SwiftUI

struct CommunityView: View {
    @StateObject private var communityViewModel = CommunityViewModel()
    @StateObject private var userViewModel = UserViewModel.shared
    
    @State private var showingCreatePost = false
    
    // Default tags based on the original UI
    let tags = ["TRENDING", "STRESS", "ANXIETY", "AFFIRMATION", "GRATITUDE", "DAILY"]
    
    var body: some View {
        ZStack(alignment: .top) {
            EliteBackgroundView()
            
            VStack(spacing: 0) {
                // Fixed Header
                headerView
                    .padding(.top, 60)
                    .padding(.bottom, 10)
                    .zIndex(10)
                
                // Content
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        if communityViewModel.posts.isEmpty && !communityViewModel.isLoading {
                            // Empty State
                            VStack(spacing: 16) {
                                Image(systemName: "person.2.square.stack")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("No posts found. Be the first to share!")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 100)
                        } else {
                            ForEach(communityViewModel.posts) { post in
                                CommunityPostCard(
                                    postWithUser: post,
                                    onLike: {
                                        Task {
                                            try? await communityViewModel.toggleLike(postId: post.id)
                                        }
                                    },
                                    onComment: {
                                        // TODO: Show comment sheet
                                        print("Comment tapped")
                                    },
                                    onShare: {
                                        sharePost(post: post)
                                    },
                                    onMenuTapped: {
                                        // TODO: Show action sheet
                                        print("Menu tapped")
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 120) // Extra padding for Tab Bar
                }
                .refreshable {
                    await communityViewModel.fetchPosts(refresh: true)
                }
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .task {
            // Initial fetch
            if communityViewModel.posts.isEmpty {
                await communityViewModel.fetchPosts()
            }
            if userViewModel.user == nil {
                await userViewModel.fetchProfile()
            }
        }
        // Native bridging to original CreatePostViewController via UIViewControllerRepresentable
        .sheet(isPresented: $showingCreatePost, onDismiss: {
            Task {
                await communityViewModel.fetchPosts(refresh: true)
            }
        }) {
            CreatePostViewBridge()
                .ignoresSafeArea()
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
                        .background(.regularMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.secondary.opacity(0.15), lineWidth: 0.5))
                }
            }
            .padding(.horizontal, 20)
            
            // Browse By Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Browse By")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(tags, id: \.self) { tag in
                            Button(action: {
                                Task {
                                   await communityViewModel.fetchPosts(page: 1, tag: tag, refresh: true)
                                }
                            }) {
                                Text(tag)
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.regularMaterial, in: Capsule())
                                    .overlay(Capsule().stroke(Color.secondary.opacity(0.15), lineWidth: 0.5))
                                    .foregroundStyle(.primary)
                            }
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
