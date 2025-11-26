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
        
        // Position tab bar at the bottom with safe area
        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            customTabBar.heightAnchor.constraint(equalToConstant: 85)
        ])
    }
}
