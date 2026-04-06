//
//  SceneDelegate.swift
//  Rewind
//
//  Created by Shyam on 04/11/25.
//

import UIKit
import Supabase


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var splashShownAt: Date?
    private let minimumSplashDuration: TimeInterval = 1.8

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        let splashVC = SplashViewController()
        window?.rootViewController = splashVC
        window?.makeKeyAndVisible()
        splashShownAt = Date()

        Task {
            if let callbackURL = connectionOptions.urlContexts.first?.url {
                await handleOAuthCallback(url: callbackURL)
                return
            }
            await resolveInitialScreen()
        }
    }

    // MARK: - Smart Routing

    @MainActor
    private func resolveInitialScreen() async {
        let supabase = SupabaseConfig.shared.client
        var nextViewController: UIViewController?

        // Check for an active session
        if let session = try? await supabase.auth.session {
            // Fetch the user's profile to check onboardingCompleted flag
            let users: [DBUser]? = try? await supabase
                .from("users")
                .select()
                .eq("id", value: session.user.id.uuidString)
                .execute()
                .value

            let isOnboardingDone = users?.first?.onboardingCompleted ?? false

            if isOnboardingDone {
                // Fully onboarded user → go straight to main tab
                nextViewController = MainTabBarController()
            } else {
                // Session exists but onboarding not done → resume from first question
                nextViewController = OnboardingHealthGoalViewController(nibName: "OnboardingHealthGoalViewController", bundle: nil)
            }
        } else {
            // No session → brand-new user, show the onboarding intro storyboard
            let onboardingStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)
            if let onboardingVC = onboardingStoryboard.instantiateInitialViewController() {
                nextViewController = onboardingVC
            }
        }

        await waitForMinimumSplashDuration()
        if let nextViewController {
            setRoot(nextViewController)
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

    @MainActor
    private func handleOAuthCallback(url: URL) async {
        do {
            _ = try await SupabaseConfig.shared.client.auth.session(from: url)
        } catch {
            SupabaseConfig.shared.client.handle(url)
        }

        await resolveInitialScreen()
    }
}
