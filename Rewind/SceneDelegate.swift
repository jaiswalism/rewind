//
//  SceneDelegate.swift
//  Rewind
//
//  Created by Shyam on 04/11/25.
//

import UIKit
import Supabase
import SwiftUI


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var splashShownAt: Date?
    private let minimumSplashDuration: TimeInterval = 1.8
    private var pendingRecoveryRoute = false
    private var initialRoutingTask: Task<Void, Never>?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        let splashVC = SplashViewController()
        window?.rootViewController = splashVC
        window?.makeKeyAndVisible()
        splashShownAt = Date()

        // Initialize Pet Companion LLM Service
        PetCompanionService.shared.setLLMService(
            PetLLMService(supabaseURL: "https://jbucoyhjtwjwockxllfp.supabase.co")
        )

        initialRoutingTask = Task {
            if let callbackURL = connectionOptions.urlContexts.first?.url {
                await handleOAuthCallback(url: callbackURL)
                return
            }

            if let universalLink = connectionOptions.userActivities.first?.webpageURL {
                await handleOAuthCallback(url: universalLink)
                return
            }

            await resolveInitialScreen()
        }
    }

    // MARK: - Smart Routing

    @MainActor
    private func resolveInitialScreen() async {
        guard !Task.isCancelled else { return }
        
        if pendingRecoveryRoute {
            pendingRecoveryRoute = false
            await waitForMinimumSplashDuration()
            setRoot(ForgotPasswordViewController())
            return
        }

        let supabase = SupabaseConfig.shared.client
        var nextViewController: UIViewController?
        let hasPendingPasswordReset = UserDefaults.standard.bool(forKey: Constants.UserDefaults.pendingPasswordReset)

        if hasPendingPasswordReset {
            if (try? await supabase.auth.session) != nil {
                try? await supabase.auth.signOut()
            }
            UserDefaults.standard.set(false, forKey: Constants.UserDefaults.pendingPasswordReset)
        }

        // Check for an active session
        if let session = try? await supabase.auth.session {
            // Try to fetch the user's profile to check onboardingCompleted flag
            let users: [DBUser]? = try? await supabase
                .from("users")
                .select()
                .eq("id", value: session.user.id.uuidString)
                .execute()
                .value

            // If we got data from the server, use it; otherwise fall back to UserDefaults
            let isOnboardingDone: Bool
            if let onboardingFromServer = users?.first?.onboardingCompleted {
                isOnboardingDone = onboardingFromServer
                // Sync the result to UserDefaults for offline resilience
                UserDefaults.standard.set(onboardingFromServer, forKey: Constants.UserDefaults.hasCompletedOnboarding)
            } else {
                // Network unavailable or query failed—check local cache
                isOnboardingDone = UserDefaults.standard.bool(forKey: Constants.UserDefaults.hasCompletedOnboarding)
            }

            if isOnboardingDone {
                // Fully onboarded user → go straight to main tab
                nextViewController = MainTabBarController()
            } else {
                // Session exists but onboarding not done → resume from first question (programmatic UIKit)
                nextViewController = GoalSelectionViewController()
            }
        } else {
            // No session → brand-new user, show the 5-page programmatic info tutorial
            var onboardingView = OnboardingView()
            onboardingView.onCompletion = { [weak self] in
                let loginVC = LoginViewController()
                self?.setRoot(loginVC)
            }
            nextViewController = UIHostingController(rootView: onboardingView)
        }

        await waitForMinimumSplashDuration()

        guard !Task.isCancelled else { return }

        if pendingRecoveryRoute {
            pendingRecoveryRoute = false
            setRoot(ForgotPasswordViewController())
            return
        }

        if let nextViewController {
            setRoot(nextViewController)
        } else {
            // Absolute fallback so we're never stuck on the splash screen
            let fallbackVC = UIViewController()
            fallbackVC.view.backgroundColor = .systemBackground
            setRoot(fallbackVC)
        }
    }

    @MainActor
    private func waitForMinimumSplashDuration() async {
        guard let splashShownAt else { return }
        let elapsed = Date().timeIntervalSince(splashShownAt)
        let remaining = minimumSplashDuration - elapsed
        guard remaining > 0 else { return }

        let nanoseconds = UInt64(remaining * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }

    /// Swaps the root view controller with a smooth cross-fade transition.
    func setRoot(_ viewController: UIViewController) {
        guard let window = window else { return }
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve, animations: {
            window.rootViewController = viewController
        })
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        Task {
            await handleOAuthCallback(url: url)
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return
        }

        Task {
            await handleOAuthCallback(url: url)
        }
    }

    @MainActor
    private func handleOAuthCallback(url: URL) async {
        let isRecoveryLink = isRecoveryCallback(url)
        pendingRecoveryRoute = isRecoveryLink

        if isRecoveryLink {
            initialRoutingTask?.cancel()
            initialRoutingTask = nil
        }

        do {
            _ = try await SupabaseConfig.shared.client.auth.session(from: url)
        } catch {
            SupabaseConfig.shared.client.handle(url)
        }

        if isRecoveryLink {
            pendingRecoveryRoute = false
            setRoot(ForgotPasswordViewController())
            return
        }

        await resolveInitialScreen()
    }

    private func isRecoveryCallback(_ url: URL) -> Bool {
        let lowercasedURL = url.absoluteString.lowercased()
        if lowercasedURL.contains("type=recovery") {
            return true
        }

        if lowercasedURL.contains("token_hash=") {
            return true
        }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           components.queryItems?.contains(where: { item in
               let name = item.name.lowercased()
               let value = item.value?.lowercased()
               return (name == "type" && value == "recovery") || name == "token_hash"
           }) == true {
            return true
        }

        if let fragment = URLComponents(string: "https://placeholder.app/?\(url.fragment ?? "")"),
           fragment.queryItems?.contains(where: { item in
               let name = item.name.lowercased()
               let value = item.value?.lowercased()
               return (name == "type" && value == "recovery") || name == "token_hash"
           }) == true {
            return true
        }

        return false
    }
}
