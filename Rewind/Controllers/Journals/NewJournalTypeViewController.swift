//
//  NewJournalTypeViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

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
        let vc = VoiceJournalViewController(nibName: "VoiceJournalViewController", bundle: nil)
           navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func textButton(_ sender: Any) {
        let vc = AddTextJournalViewController(nibName: "AddTextJournalViewController", bundle: nil)
            navigationController?.pushViewController(vc, animated: true)
    }
}
