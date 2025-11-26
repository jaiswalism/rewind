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
    }
    @IBAction func backButton(_ sender: Any) {
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
