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
        customTabBar.delegate = self
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customTabBar)
        
        // Position tab bar at the bottom with safe area
        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            customTabBar.heightAnchor.constraint(equalToConstant: 85)
        ])
    }
}

// MARK: - CustomTabBarDelegate
extension HomePetsViewController: CustomTabBarDelegate {
    func tabBar(_ tabBar: CustomTabBar, didSelectItemAt index: Int) {
        // Handle tab selection
        print("Selected tab at index: \(index)")
        
        // You can add navigation logic here based on the index:
        // 0: Journal
        // 1: Goals
        // 2: Home (Paw)
        // 3: Care Corner
        // 4: Community
    }
}
