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
        
//      Change this for testing a particular screen and change the controller file
        var testing = false
        let testScene = OnboardingGenderViewController()

        // Always show the Onboarding storyboard
        if(!testing){
            let onboardingStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)
            let onboardingViewController = onboardingStoryboard.instantiateInitialViewController()
            window?.rootViewController = onboardingViewController
        }else{
            window?.rootViewController = testScene
        }

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
