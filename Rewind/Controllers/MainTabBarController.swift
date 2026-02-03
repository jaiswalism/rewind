//
//  MainTabBarController.swift
//  Rewind
//
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomTabBar()
        setupViewControllers()
    }
    
    private func setupCustomTabBar() {
        // Replace default tab bar with custom liquid glass tab bar
        let customTabBar = CustomTabBar()
        setValue(customTabBar, forKey: "tabBar")
    }
    
    private func setupViewControllers() {
        // Journal Tab
        let journalsVC = JournalsHomeViewController(nibName: "JournalsHomeViewController", bundle: nil)
        journalsVC.tabBarItem = UITabBarItem(
            title: "Journal",
            image: UIImage(systemName: "doc.text"),
            selectedImage: UIImage(systemName: "doc.text.fill")
        )
        let journalsNav = UINavigationController(rootViewController: journalsVC)
        
        // Home/Pets Tab
        let homePetsVC = HomePetsViewController(nibName: "HomePetsViewController", bundle: nil)
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
        let communityVC = CommunityFeedViewController(nibName: "CommunityFeedViewController", bundle: nil)
        communityVC.tabBarItem = UITabBarItem(
            title: "Community",
            image: UIImage(systemName: "person.2"),
            selectedImage: UIImage(systemName: "person.2.fill")
        )
        let communityNav = UINavigationController(rootViewController: communityVC)
        
        // Set view controllers
        viewControllers = [journalsNav, homePetsNav, careCornerNav, communityNav]
        
        // Set default selected tab (Home/Pets - index 1)
        selectedIndex = 1
    }
}