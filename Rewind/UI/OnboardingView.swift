import SwiftUI

// MARK: - Model
struct OnboardingPage: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let subtitle: String?
}

// MARK: - Data
let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        imageName: "illustrations/onboarding/praying",
        title: "Personalize Your Mental Health State With Rewind",
        subtitle: nil
    ),
    OnboardingPage(
        imageName: "illustrations/onboarding/crying",
        title: "Mood Journaling & AI Companion",
        subtitle: nil
    ),
    OnboardingPage(
        imageName: "illustrations/onboarding/reading",
        title: "Understand Your Emotions Better Everyday",
        subtitle: nil
    ),
    OnboardingPage(
        imageName: "illustrations/onboarding/heart",
        title: "Build A Healthier Relationship With Yourself",
        subtitle: nil
    ),
    OnboardingPage(
        imageName: "illustrations/onboarding/girl",
        title: "Ready to Refuel, Reflect & Rewind?",
        subtitle: nil
    )
]

// MARK: - View
struct OnboardingView: View {

    @State private var currentPage = 0
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Adaptive Colors
    var isDark: Bool { colorScheme == .dark }

    var cardBackground: Color {
        isDark ? Color.eliteSurface : Color.eliteSurface
    }

    var cardBorder: Color {
        Color.eliteBorder
    }

    var titleColor: Color {
        Color.eliteTextPrimary
    }

    var indicatorActive: Color {
        Color.eliteAccentPrimary
    }

    var indicatorInactive: Color {
        Color.eliteBorder
    }

    var buttonBackground: Color {
        Color.eliteAccentPrimary
    }

    var buttonText: Color {
        .white
    }

    var isLastPage: Bool {
        currentPage == onboardingPages.count - 1
    }

    var onCompletion: (() -> Void)?

    var body: some View {
        ZStack {

            // 🔥 YOUR APP THEME BACKGROUND
            EliteBackgroundView()

            VStack {
                Spacer()

                // MARK: - Card
                VStack(spacing: 28) {

                    // Image (portrait friendly)
                    Image(onboardingPages[currentPage].imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .shadow(color: .black.opacity(isDark ? 0.25 : 0.1), radius: 20, y: 10)

                    // Title
                    Text(onboardingPages[currentPage].title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.eliteTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    // Indicators
                    HStack(spacing: 6) {
                        ForEach(onboardingPages.indices, id: \.self) { idx in
                            Capsule()
                                .fill(idx == currentPage ? indicatorActive : indicatorInactive)
                                .frame(width: idx == currentPage ? 18 : 6, height: 6)
                                .animation(.easeInOut(duration: 0.25), value: currentPage)
                        }
                    }

                    // Button
                    Button {
                        if !isLastPage {
                            withAnimation(.easeInOut) {
                                currentPage += 1
                            }
                        } else {
                            handleOnboardingComplete()
                        }
                    } label: {
                        Text(isLastPage ? "Get Started" : "Next")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ElitePrimaryButtonStyle())
                }
                .padding(28)
                .frame(maxWidth: 420)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(cardBorder, lineWidth: 1)
                )
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    // MARK: - Actions
    private func handleOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: Constants.UserDefaults.hasCompletedOnboarding)
        onCompletion?()
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
}