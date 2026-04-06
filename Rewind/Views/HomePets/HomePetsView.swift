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
    @StateObject private var talkSession: PetTalkSessionViewModel
    @StateObject private var userViewModel: UserViewModel
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(Constants.UserDefaults.selectedPetMartStyle) private var selectedPetMartStyle = "basicPanda"

    var onSettingsTapped:      () -> Void = {}
    var onPetMartTapped:       () -> Void = {}
    // onMicTapped removed – talk is now inline

    @State private var showBubble = false
    @State private var isTalking  = false   // drives the inline panel
    @State private var bubbleQuote = ""
    @State private var hasInitializedData = false
    @State private var selectedStatTopic: HomeStatInfoTopic?

    init() {
        let pet = PetViewModel()
        _viewModel   = StateObject(wrappedValue: pet)
        _talkSession = StateObject(wrappedValue: PetTalkSessionViewModel(petViewModel: pet))
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

                // Action row stays; it just morphs into the talk panel
                if isTalking {
                    talkPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    actionSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
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
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: isTalking)
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

            if showBubble && !isTalking {
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
                talkSession.openSession()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    isTalking = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "mic.fill")
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

    // MARK: - Talk Panel

    private var talkPanel: some View {
        VStack(spacing: 0) {
            // handle + close row
            HStack {
                Spacer()
                Button {
                    talkSession.closeSession()
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        isTalking = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .accessibilityLabel("Close conversation")
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            // Animated blob + mic
            ZStack {
                BlobRing(scale: 1 + CGFloat(talkSession.audioLevel) * 0.55,
                         opacity: 0.12 + Double(talkSession.audioLevel) * 0.25,
                         diameter: 130)
                BlobRing(scale: 1 + CGFloat(talkSession.audioLevel) * 0.40,
                         opacity: 0.20 + Double(talkSession.audioLevel) * 0.30,
                         diameter: 100)
                BlobRing(scale: 1 + CGFloat(talkSession.audioLevel) * 0.25,
                         opacity: 0.50 + Double(talkSession.audioLevel) * 0.30,
                         diameter: 72)

                Button(action: { talkSession.toggleMic() }) {
                    ZStack {
                        Circle()
                            .fill(micFill)
                            .frame(width: 60, height: 60)
                            .shadow(color: micShadow, radius: 10, y: 4)

                        Image(systemName: micIcon)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .accessibilityLabel(talkSession.sessionState == .listening ? "Stop recording" : "Start recording")
                .disabled(!micEnabled)
                .scaleEffect(talkSession.sessionState == .listening ? 1.08 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6),
                            value: talkSession.sessionState == .listening)
            }
            .frame(height: 140)

            // Status + text area
            VStack(spacing: 6) {
                Text(statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .animation(.easeInOut(duration: 0.2), value: statusText)

                ScrollView {
                    Text(displayText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .animation(.easeInOut(duration: 0.25), value: displayText)
                }
                .frame(maxHeight: 80)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Talk Panel Helpers

    private var micIcon: String {
        switch talkSession.sessionState {
        case .listening:    return "mic.slash.fill"
        case .thinking:     return "ellipsis"
        case .responding:   return "speaker.wave.2.fill"
        default:            return "mic.fill"
        }
    }

    private var micFill: Color {
        switch talkSession.sessionState {
        case .listening:  return Color(red: 0.9, green: 0.2, blue: 0.2)
        case .thinking:   return Color(red: 0.55, green: 0.45, blue: 0.95)
        case .responding: return Color(red: 0.25, green: 0.72, blue: 0.55)
        default:          return Color(red: 0.38, green: 0.38, blue: 1.0)
        }
    }

    private var micShadow: Color {
        micFill.opacity(0.45)
    }

    private var micEnabled: Bool {
        switch talkSession.sessionState {
        case .thinking, .responding: return false
        default: return true
        }
    }

    private var statusText: String {
        switch talkSession.sessionState {
        case .idle:           return "Tap to talk"
        case .listening:      return "Listening"
        case .thinking:       return "Thinking…"
        case .responding:     return "Responding"
        case .error(let msg): return msg
        }
    }

    private var displayText: String {
        switch talkSession.sessionState {
        case .listening:     return talkSession.transcription.isEmpty ? "…" : talkSession.transcription
        case .thinking:      return talkSession.transcription
        case .responding,
             .idle where !talkSession.petResponse.isEmpty:
            return talkSession.petResponse
        case .error(let m):  return m
        default:             return ""
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
