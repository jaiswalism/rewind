//
//  OnboardingScreenViewController.swift
//  Rewind
//
//  Created by Shyam on 05/11/25.
//

import UIKit
import SwiftUI // 1. Import SwiftUI

class OnboardingScreenViewController: UIViewController {

    @IBOutlet var bottomView: UIView!
    @IBOutlet var nextBtn1: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Your existing code
        nextBtn1.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nextBtn1.widthAnchor.constraint(equalToConstant: 80),
            nextBtn1.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    // 2. This is the new hand-off action
    // We will connect the FINAL button in the storyboard to this
    @IBAction func finishOnboardingTapped(_ sender: Any) {
        let loginVC = LoginViewController()
          
          // Present it full screen
          loginVC.modalPresentationStyle = .fullScreen
          self.present(loginVC, animated: true, completion: nil)
          
          // Optional: Mark onboarding as complete (if you plan to skip next time)
          UserDefaults.standard.set(true, forKey: "onboardingCompleted")
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
