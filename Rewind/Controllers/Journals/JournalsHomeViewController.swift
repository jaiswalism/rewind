//
//  JournalsHomeViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

class JournalsHomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func addJournal(_ sender: Any) {
        let vc = NewJournalTypeViewController(nibName: "NewJournalTypeViewController", bundle: nil)
            self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func viewJournals(_ sender: Any) {
        let vc = MyJournalsListViewController(nibName: "MyJournalsListViewController", bundle: nil)
            navigationController?.pushViewController(vc, animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
