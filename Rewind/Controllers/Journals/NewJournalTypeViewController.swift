//
//  NewJournalTypeViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit
import SwiftUI

class NewJournalTypeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        hidesBottomBarWhenPushed = true
        setupBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setupBackButton() {
        GlassBackButton.add(to: self, action: #selector(backButtonTapped))
    }

    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    @IBAction func voiceButton(_ sender: Any) {
        let swiftUIView = AddJournalView()
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.modalPresentationStyle = .fullScreen
        self.present(hostingController, animated: true)
    }
    @IBAction func textButton(_ sender: Any) {
        let swiftUIView = AddJournalView()
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.modalPresentationStyle = .fullScreen
        self.present(hostingController, animated: true)
    }
}
