import SwiftUI

struct CareCornerView: View {
    @StateObject private var viewModel = CareCornerViewModel()
    @State private var hasLoaded = false
    @State private var showingCompletionAlert = false

    let onBreathingTapped: () -> Void
    let onMeditationTapped: () -> Void

    var body: some View {
        ZStack {
            EliteBackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    heroSection
                    statsSection
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

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Your rhythm")

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                metricCard(title: "Paws", value: viewModel.stats?.pawsBalance ?? 0, icon: "pawprint.fill", tint: .eliteAccentPrimary)
                metricCard(title: "Breathing", value: viewModel.stats?.totalBreathingExercises ?? 0, icon: "wind", tint: Color(red: 0.25, green: 0.72, blue: 0.55))
                metricCard(title: "Meditation", value: viewModel.stats?.totalMeditationSessions ?? 0, icon: "moon.stars.fill", tint: Color(red: 0.5, green: 0.55, blue: 0.95))
                metricCard(title: "Challenges", value: viewModel.stats?.totalChallengesCompleted ?? 0, icon: "checkmark.seal.fill", tint: Color(red: 1.0, green: 0.62, blue: 0.25))
            }
        }
    }

    private var dailyChallengeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Today's challenge")

            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .bottomLeading) {
                    Image("illustrations/careCorner/topSectionBG")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 190)
                        .clipped()

                    LinearGradient(
                        colors: [Color.black.opacity(0.08), Color.black.opacity(0.48)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

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
                            Task {
                                do {
                                    try await viewModel.completeChallenge()
                                    showingCompletionAlert = true
                                } catch {
                                    viewModel.error = error.localizedDescription
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.challengeCompleted ? "checkmark.circle.fill" : "sparkles")
                                Text(viewModel.challengeCompleted ? "Challenge completed" : "Complete challenge")
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
                        .disabled(viewModel.challengeCompleted || viewModel.dailyChallenge == nil)
                    }
                    .padding(18)
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
            sectionTitle("Quick resets")

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

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.primary)
    }

    private func metricCard(title: String, value: Int, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tint)
                Spacer()
            }

            Text("\(value)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
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
    }
}