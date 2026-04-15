import SwiftUI

// MARK: - Onboarding Container View
/// A page-based onboarding flow that works on both iPhone and iPad
struct OnboardingContainerView: View {
    @State private var currentPage = 0
    @Environment(\.dismiss) var dismiss
    
    let totalPages = 4
    var onCompletion: (() -> Void)?
    
    var body: some View {
        ZStack {
            switch currentPage {
            case 0:
                OnboardingHealthGoalView(currentPage: $currentPage)
            case 1:
                OnboardingGenderView(currentPage: $currentPage)
            case 2:
                OnboardingAgeView(currentPage: $currentPage)
            case 3:
                OnboardingProfHelpView(currentPage: $currentPage)
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
        .onChange(of: currentPage) { _, newValue in
            if newValue >= totalPages {
                // Onboarding complete
                UserDefaults.standard.set(true, forKey: Constants.UserDefaults.hasCompletedOnboarding)
                onCompletion?()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingContainerView()
}
