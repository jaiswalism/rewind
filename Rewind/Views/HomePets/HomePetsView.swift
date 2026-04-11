import SwiftUI
import SceneKit

// MARK: - Mood State

private struct MoodState {
    let quotes: [String]

    func randomQuote() -> String {
        quotes.randomElement() ?? "Tell me about your day."
    }

    static func from(_ pet: PetViewModel.PetData?) -> MoodState {
        let emotion = pet?.memory?.dominantEmotion?.lowercased() ?? ""
        let mood = pet?.state.mood ?? 65
        switch true {
        case emotion.contains("sad") || emotion.contains("melanchol") || mood < 30:
            return MoodState(quotes: [
                "I could use some company today.",
                "Can we stay close for a bit?",
                "A little chat would cheer me up."
            ])
        case emotion.contains("excit") || emotion.contains("joy") || mood > 80:
            return MoodState(quotes: [
                "So happy you're here! ✨",
                "Yay, you're back!",
                "Best part of my day is you."
            ])
        case emotion.contains("sleep") || emotion.contains("tired") || mood < 48:
            return MoodState(quotes: [
                "Feeling a little sleepy...",
                "Can we keep it cozy today?",
                "Low-energy mode, but still here with you."
            ])
        case emotion.contains("curious"):
            return MoodState(quotes: [
                "Wondering what you'll share.",
                "Tell me something interesting.",
                "I'm curious about your day."
            ])
        default:
            return MoodState(quotes: [
                "Tell me about your day.",
                "How's everything going?",
                "I'm listening whenever you're ready."
            ])
        }
    }
}

private enum HomeStatInfoTopic: String, Identifiable {
    case paws
    case mood

    var id: String { rawValue }
}

// MARK: - Home View

struct HomePetsView: View {
    @StateObject private var viewModel:   PetViewModel
    @StateObject private var talkSession: PetConversationSessionViewModel
    @StateObject private var userViewModel: UserViewModel
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(Constants.UserDefaults.selectedPetMartStyle) private var selectedPetMartStyle = "basicPanda"

    var onSettingsTapped:      () -> Void = {}
    var onPetMartTapped:       () -> Void = {}

    @State private var showBubble = false
    @State private var bubbleQuote = ""
    @State private var hasInitializedData = false
    @State private var selectedStatTopic: HomeStatInfoTopic?
    @State private var showingTalkSession = false

    init() {
        let pet = PetViewModel()
        _viewModel   = StateObject(wrappedValue: pet)
        _talkSession = StateObject(wrappedValue: PetConversationSessionViewModel(petViewModel: pet))
        _userViewModel = StateObject(wrappedValue: UserViewModel.shared)
    }

    private var mood: MoodState { MoodState.from(viewModel.pet) }

    var body: some View {
        ZStack(alignment: .bottom) {
            EliteBackgroundView()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                Spacer(minLength: 0)

                petSection
                    .padding(.horizontal, 24)

                Spacer(minLength: 0)

                actionSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .task {
            guard !hasInitializedData else { return }
            hasInitializedData = true

            await viewModel.fetchPet()
            await MainActor.run {
                bubbleQuote = mood.randomQuote()
            }
        }
        .task { await userViewModel.fetchProfile() }
        .onAppear {
            if bubbleQuote.isEmpty {
                bubbleQuote = mood.randomQuote()
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.35)) {
                showBubble = true
            }
        }
        .sheet(item: $selectedStatTopic) { topic in
            HomeStatsInfoSheet(topic: topic)
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showingTalkSession, onDismiss: {
            talkSession.closeSession()
        }) {
            PetTalkingSessionView(viewModel: talkSession)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: onSettingsTapped) {
                if let urlString = userViewModel.user?.profileImageUrl,
                   !urlString.isEmpty,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(Color.primary.opacity(0.1))
                                .frame(width: 32, height: 32)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        case .failure:
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.primary)
                        @unknown default:
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.primary)
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.primary)
                }
            }

            Spacer()

            HStack(spacing: 20) {
                statChip("pawprint.fill",
                         "\(userViewModel.user?.pawsBalance ?? 0) pts",
                         color: Color(red: 0.55, green: 0.75, blue: 1.0),
                         topic: .paws)
                statChip("face.smiling.fill",
                         "\(Int(viewModel.pet?.state.mood ?? 80))%",
                         color: Color(red: 0.35, green: 0.78, blue: 0.45),
                         topic: .mood)
            }

            Spacer()
        }
    }

    private func statChip(_ icon: String, _ value: String, color: Color, topic: HomeStatInfoTopic) -> some View {
        Button {
            selectedStatTopic = topic
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Shows details about this stat")
    }

    // MARK: - Pet Section

    private var petSection: some View {
        ZStack(alignment: .center) {
            petAvatar
                .frame(maxWidth: .infinity, idealHeight: 340)
                .frame(height: 340)
                .clipped()
                .offset(x: -14, y: 30)

            Ellipse()
                .fill(Color.black.opacity(colorScheme == .dark ? 0.28 : 0.09))
                .frame(width: 110, height: 13)
                .blur(radius: 7)
                .offset(x: -14, y: 198)

            if showBubble {
                speechBubble
                    .offset(x: 50, y: -170)
                    .transition(.scale(scale: 0.5, anchor: .bottomLeading).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 360)
    }

    @ViewBuilder
    private var petAvatar: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(.primary)
        } else {
            PetAvatarViewRepresentable(scale: 0.14, position: SCNVector3(0, -2.0, 0))
                .id(selectedPetMartStyle)
        }
    }

    // MARK: - Speech Bubble

    private var speechBubble: some View {
        Text(bubbleQuote.isEmpty ? (mood.quotes.first ?? "Tell me about your day.") : bubbleQuote)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
            .lineLimit(3)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: 158, alignment: .leading)
            .background(
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)

                    BubbleTail()
                        .fill(.regularMaterial)
                        .frame(width: 14, height: 9)
                        .offset(x: 16, y: 8)
                }
            )
    }

    // MARK: - Default Actions

    private var actionSection: some View {
        VStack(spacing: 12) {
            Button {
                showingTalkSession = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "message.and.waveform.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Talk")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .buttonStyle(ElitePrimaryButtonStyle())

            Button(action: onPetMartTapped) {
                HStack(spacing: 8) {
                    Image(systemName: "bag")
                        .font(.system(size: 14, weight: .medium))
                    Text("Pet Mart")
                        .font(.system(size: 15, weight: .medium))
                }
            }
            .buttonStyle(EliteSocialButtonStyle())
        }
    }

}

private struct HomeStatsInfoSheet: View {
    let topic: HomeStatInfoTopic

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    if topic == .paws {
                        card(
                            title: "Paws points",
                            icon: "pawprint.fill",
                            iconColor: Color(red: 0.55, green: 0.75, blue: 1.0),
                            lines: [
                                "This is your current points balance.",
                                "You can earn paws by completing care challenges and mindful sessions.",
                                "Pet Mart redemption is coming soon."
                            ]
                        )

                        card(
                            title: "How to earn paws",
                            icon: "sparkles",
                            iconColor: Color(red: 1.0, green: 0.62, blue: 0.25),
                            lines: [
                                "Complete the daily challenge in Care Corner.",
                                "Finish qualifying breathing sessions.",
                                "Finish qualifying meditation sessions."
                            ]
                        )

                        card(
                            title: "How paws will be used",
                            icon: "bag.fill",
                            iconColor: Color(red: 0.64, green: 0.54, blue: 0.92),
                            lines: [
                                "Pet Mart purchases will use paws points.",
                                "You will be able to unlock pet items and goodies.",
                                "Pet Mart setup is in progress."
                            ]
                        )
                    } else {
                        card(
                            title: "Mood score",
                            icon: "face.smiling.fill",
                            iconColor: Color(red: 0.35, green: 0.78, blue: 0.45),
                            lines: [
                                "This is your pet's current mood estimate.",
                                "Talking with your pet and consistent care activities can help improve it.",
                                "Higher mood reflects better recent emotional wellbeing."
                            ]
                        )

                        card(
                            title: "How mood improves",
                            icon: "heart.fill",
                            iconColor: Color(red: 0.95, green: 0.38, blue: 0.45),
                            lines: [
                                "Talk with your pet regularly.",
                                "Complete care activities consistently.",
                                "Check in daily to keep your bond strong."
                            ]
                        )
                    }
                }
                .padding(20)
            }
            .navigationTitle("Stats info")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func card(title: String, icon: String, iconColor: Color, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
            }

            ForEach(lines, id: \.self) { line in
                Text("• \(line)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Blob Ring

private struct BlobRing: View {
    let scale:    CGFloat
    let opacity:  Double
    let diameter: CGFloat

    var body: some View {
        Circle()
            .fill(Color(red: 0.38, green: 0.38, blue: 1.0).opacity(opacity))
            .frame(width: diameter, height: diameter)
            .scaleEffect(scale)
            .animation(.linear(duration: 0.08), value: scale)
    }
}

// MARK: - Bubble Tail

private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: rect.width, y: 0))
            p.addLine(to: CGPoint(x: rect.width * 0.25, y: rect.height))
            p.closeSubpath()
        }
    }
}
