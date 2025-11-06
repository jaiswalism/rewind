//
//  OnboardingScreenViewController.swift
//  Rewind
//
//  Created by Shyam on 05/11/25.
//

import UIKit

class OnboardingScreenViewController: UIViewController {

    @IBOutlet var bottomView: UIView!
    @IBOutlet var nextBtn1: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // This tells the system we wll define constraints for this button in code.
        nextBtn1.translatesAutoresizingMaskIntoConstraints = false
        
        // Activate width and height constraints.
        NSLayoutConstraint.activate([
            nextBtn1.widthAnchor.constraint(equalToConstant: 80), // Your desired width
            nextBtn1.heightAnchor.constraint(equalToConstant: 80)   // Your desired height
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
