//
//  JournalDetailViewViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

class JournalDetailViewViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setupBackButton() {
        GlassBackButton.add(to: self, action: #selector(backButtonTapped(_:)))
    }

    @objc func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
