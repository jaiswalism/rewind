//
//  JournalsHomeViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

class JournalsHomeViewController: UIViewController {
    
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
        
        // Select the journal tab (index 0)
        customTabBar.selectTab(at: 0)
    }

    @IBAction func addJournal(_ sender: Any) {
        let vc = NewJournalTypeViewController(nibName: "NewJournalTypeViewController", bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func viewJournals(_ sender: Any) {
        let vc = MyJournalsListViewController(nibName: "MyJournalsListViewController", bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
    }
}
