//
//  JournalsHomeViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

class JournalsHomeViewController: UIViewController {
    
    // MARK: - Properties

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Setup
    
    @IBAction func addJournal(_ sender: Any) {
        let vc = NewJournalTypeViewController(nibName: "NewJournalTypeViewController", bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func viewJournals(_ sender: Any) {
        let vc = MyJournalsListViewController(nibName: "MyJournalsListViewController", bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
    }
}
