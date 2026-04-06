import SwiftUI

struct CareCornerView: View {
    private enum ActiveSheet: Identifiable, Equatable {
        case challengeComposer

        var id: String {
            switch self {
            case .challengeComposer:
                return "challengeComposer"
            }
        }
    }

    @StateObject private var viewModel = CareCornerViewModel()
    @StateObject private var userViewModel = UserViewModel.shared
    @State private var hasLoaded = false
    @State private var showingCompletionAlert = false
    @State private var showingChallengeErrorAlert = false
    @State private var activeSheet: ActiveSheet?
    @State private var challengePostPrefill: CareCornerViewModel.ChallengeCommunityPrefill?
    @State private var isCompletingChallenge = false
    @State private var shouldShowCompletionAfterComposer = false

    let onBreathingTapped: () -> Void
    let onMeditationTapped: () -> Void
    var body: some View {
        ZStack {
            EliteBackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    heroSection
                    CareCornerProgressSection(
                        viewModel: viewModel,
                        pawsBalance: userViewModel.user?.pawsBalance ?? 0
                    )
                    dailyChallengeSection
                    quickResetSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            await loadContent()
        }
        .alert("Challenge Completed!", isPresented: $showingCompletionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Great job. You earned 10 paws.")
        }
        .alert("Couldn't Complete Challenge", isPresented: $showingChallengeErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.error ?? "Please try again.")
        }
        .sheet(item: $activeSheet, onDismiss: {
            if shouldShowCompletionAfterComposer {
                shouldShowCompletionAfterComposer = false
                showingCompletionAlert = true
            }
        }) {
            switch $0 {
            case .challengeComposer:
                if let challengePostPrefill {
                    CreatePostView(initialText: challengePostPrefill.text, initialTags: challengePostPrefill.tags)
                        .presentationCornerRadius(28)
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Care Corner")
                .font(.system(size: 34, weight: .bold, design: .default))
                .foregroundStyle(.primary)

            Text("Quick reset tools for quieter moments.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Pick one reset and move at your own pace.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.eliteAccentPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.eliteAccentPrimary.opacity(0.12), in: Capsule())
        }
    }

    private var dailyChallengeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's challenge")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.dailyChallenge?.title ?? "Daily Mindfulness")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundStyle(.white)

                                Text(viewModel.dailyChallenge?.description ?? "Take a moment to practice gratitude today.")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.92))
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 8)

                            Text("10 paws")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.24), in: Capsule())
                        }

                        if viewModel.challengeCompleted {
                            Text("Completed")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.white)
                        }

                        Button {
                            Task { @MainActor in
                                isCompletingChallenge = true

                                if viewModel.dailyChallenge == nil {
                                    await viewModel.fetchDailyChallenge()
                                }

                                let prefill = viewModel.communityPrefillForCurrentChallenge() ?? viewModel.communityPrefillFallbackForToday()
                                challengePostPrefill = prefill
                                activeSheet = .challengeComposer

                                let shouldCompleteChallenge = !viewModel.challengeCompleted && viewModel.dailyChallenge != nil

                                do {
                                    let wasCompleted = viewModel.challengeCompleted
                                    if shouldCompleteChallenge {
                                        try await viewModel.completeChallenge()
                                    }
                                    if shouldCompleteChallenge && !wasCompleted {
                                        if activeSheet == .challengeComposer {
                                            shouldShowCompletionAfterComposer = true
                                        } else {
                                            showingCompletionAlert = true
                                        }
                                    }
                                } catch {
                                    // If posting composer is already open, completion failure should not block sharing.
                                    if activeSheet != .challengeComposer {
                                        viewModel.error = error.localizedDescription
                                        showingChallengeErrorAlert = true
                                    }
                                }

                                isCompletingChallenge = false
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isCompletingChallenge {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(Color(red: 0.25, green: 0.28, blue: 0.86))
                                    Text("Completing...")
                                } else {
                                    Image(systemName: viewModel.challengeCompleted ? "square.and.arrow.up" : "sparkles")
                                    Text(viewModel.challengeCompleted ? "Post today's challenge" : "Complete challenge")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(viewModel.challengeCompleted ? Color.white.opacity(0.75) : Color(red: 0.25, green: 0.28, blue: 0.86))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(viewModel.challengeCompleted ? Color.white.opacity(0.16) : Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(viewModel.challengeCompleted ? 0.14 : 0.0), lineWidth: 1)
                        )
                        .disabled(isCompletingChallenge)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background {
                    ZStack {
                        Image("illustrations/careCorner/topSectionBG")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()

                        LinearGradient(
                            colors: [Color.black.opacity(0.08), Color.black.opacity(0.48)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 14, y: 7)
            }
        }
    }

    private var quickResetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick resets")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)

            VStack(spacing: 12) {
                actionCard(
                    title: "Breathing",
                    subtitle: "Slow your pace",
                    systemImage: "wind",
                    assetName: "illustrations/careCorner/breathingBtnBg",
                    tint: Color(red: 0.25, green: 0.72, blue: 0.55),
                    action: onBreathingTapped
                )

                actionCard(
                    title: "Meditation",
                    subtitle: "Settle in quietly",
                    systemImage: "moon.stars.fill",
                    assetName: "illustrations/careCorner/meditationBtnBg",
                    tint: Color(red: 0.5, green: 0.55, blue: 0.95),
                    action: onMeditationTapped
                )
            }
        }
    }

    private func actionCard(
        title: String,
        subtitle: String,
        systemImage: String,
        assetName: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 146)
                    .clipped()

                LinearGradient(
                    colors: [Color.black.opacity(0.0), Color.black.opacity(0.34)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(tint.opacity(0.9), in: Circle())

                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity, minHeight: 146)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func loadContent() async {
        await viewModel.fetchDailyChallenge()
        await viewModel.fetchStats()
        await userViewModel.fetchProfile()
    }
}