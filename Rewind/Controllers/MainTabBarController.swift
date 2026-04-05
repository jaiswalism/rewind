//
//  MainTabBarController.swift
//  Rewind
//

import UIKit
import SwiftUI

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
    }

    private func setupViewControllers() {
        // Journal Tab
        let journalsVC = JournalsViewController()
        journalsVC.tabBarItem = UITabBarItem(
            title: "Journal",
            image: UIImage(systemName: "doc.text"),
            selectedImage: UIImage(systemName: "doc.text.fill")
        )
        let journalsNav = UINavigationController(rootViewController: journalsVC)

        // Home/Pets Tab
        let homePetsVC = HomePetsViewController()
        homePetsVC.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "pawprint"),
            selectedImage: UIImage(systemName: "pawprint.fill")
        )
        let homePetsNav = UINavigationController(rootViewController: homePetsVC)

        // Care Corner Tab
        let careCornerVC = CareCornerViewController()
        careCornerVC.tabBarItem = UITabBarItem(
            title: "Care",
            image: UIImage(systemName: "brain.head.profile"),
            selectedImage: UIImage(systemName: "brain.head.profile.fill")
        )
        let careCornerNav = UINavigationController(rootViewController: careCornerVC)

        // Community Tab
        let communityVC = UIHostingController(rootView: CommunityView())
        communityVC.tabBarItem = UITabBarItem(
            title: "Community",
            image: UIImage(systemName: "person.2"),
            selectedImage: UIImage(systemName: "person.2.fill")
        )
        let communityNav = UINavigationController(rootViewController: communityVC)
        communityNav.isNavigationBarHidden = true

        // Set view controllers — Home first
        viewControllers = [homePetsNav, journalsNav, careCornerNav, communityNav]
    }
}