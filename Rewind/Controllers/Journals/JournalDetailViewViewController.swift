//
//  JournalDetailViewViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

class JournalDetailViewViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
