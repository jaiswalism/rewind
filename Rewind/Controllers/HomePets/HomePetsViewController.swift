//
//  HomePetsViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

class HomePetsViewController: UIViewController {
    
    // MARK: - Properties
    private let customTabBar = CustomTabBar()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomTabBar()
    }
    
    // MARK: - Setup
    private func setupCustomTabBar() {
        customTabBar.parentViewController = self
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customTabBar)
        
        // Position tab bar at the very bottom of the screen
        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 10),
            customTabBar.heightAnchor.constraint(equalToConstant: 110)
        ])
    }
    @IBAction func buttontaped(_ sender: Any) {
        // Present NotificationsViewController instead of Settings
        let notificationsVC = NotificationsViewController()
        if let navController = navigationController {
            navController.pushViewController(notificationsVC, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: notificationsVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
    
    @IBAction func settingsProfile(_ sender: Any) {
        let settingsVC = SettingsViewController()
        if let navController = navigationController {
            navController.pushViewController(settingsVC, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: settingsVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
}
