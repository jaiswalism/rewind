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
        submitOnboarding(seekingHelp: true)
    }
    
    @IBAction func noButton(_ sender: Any) {
        submitOnboarding(seekingHelp: false)
    }
    
    private func submitOnboarding(seekingHelp: Bool) {
        OnboardingDataManager.shared.seekingProfessionalHelp = seekingHelp
        
        // Show loading if possible
        
        OnboardingDataManager.shared.submit { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    let homePetsVC = HomePetsViewController(nibName: "HomePetsViewController", bundle: nil)
                    homePetsVC.modalPresentationStyle = .fullScreen
                    self?.present(homePetsVC, animated: true, completion: nil)
                    
                case .failure(let error):
                    let message = (error as? APIError).map {
                        if case .serverError(let msg) = $0 { return msg }
                        return error.localizedDescription
                    } ?? error.localizedDescription
                    
                    let alert = UIAlertController(title: "Onboarding Failed", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
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
