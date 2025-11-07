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
        // 1. Mark onboarding as complete so the app will skip it next time.
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")

        // 2. Instantiate the SignupViewController.
        let signupViewController = SignupViewController()

        // 3. Transition to the new view controller.
        guard let window = view.window else { return }

        window.rootViewController = signupViewController
        UIView.transition(with: window,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: nil,
                          completion: nil)
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
