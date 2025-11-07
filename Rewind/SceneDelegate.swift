//
//  SceneDelegate.swift
//  Rewind
//
//  Created by Shyam on 04/11/25.
//

import UIKit
import SwiftUI // 1. Import SwiftUI


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        // Always show the Onboarding storyboard
        let onboardingStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)
        let onboardingViewController = onboardingStoryboard.instantiateInitialViewController()
        window?.rootViewController = onboardingViewController

        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}
