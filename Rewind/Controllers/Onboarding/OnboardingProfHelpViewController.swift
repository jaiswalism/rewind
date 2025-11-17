//
//  OnboardingProfHelpViewController.swift
//  Rewind
//
//  Created by Shyam on 07/11/25.
//

import UIKit

class OnboardingProfHelpViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    @IBAction func backButton(_ sender: Any) {
        // Navigate back to OnboardingAgeViewController (XIB)
                let ageVC = OnboardingAgeViewController(nibName: "OnboardingAgeViewController", bundle: nil)
                ageVC.modalPresentationStyle = .fullScreen
                present(ageVC, animated: true, completion: nil)
    }
    @IBAction func yesButton(_ sender: Any) {
        let homePetsVC = HomePetsViewController(nibName: "HomePetsViewController", bundle: nil)
            homePetsVC.modalPresentationStyle = .fullScreen
            present(homePetsVC, animated: true, completion: nil)
    }
    
    @IBAction func noButton(_ sender: Any) {
        let homePetsVC = HomePetsViewController(nibName: "HomePetsViewController", bundle: nil)
            homePetsVC.modalPresentationStyle = .fullScreen
            present(homePetsVC, animated: true, completion: nil)
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
