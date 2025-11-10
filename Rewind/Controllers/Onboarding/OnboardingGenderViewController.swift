//
//  OnboardingGenderViewController.swift
//  Rewind
//
//  Created by Shyam on 07/11/25.
//

import UIKit

class OnboardingGenderViewController: UIViewController {
    
    @IBOutlet var genderButtons: [UIButton]!
    @IBOutlet weak var nextButton: UIButton!
    
    let maleSelectedImage = UIImage(named: "illustrations/onboarding/Male Selected")
    let maleUnselectedImage = UIImage(named: "illustrations/onboarding/Male Unselected")
    let femaleSelectedImage = UIImage(named: "illustrations/onboarding/Female Selected")
    let femaleUnselectedImage = UIImage(named: "illustrations/onboarding/Female Unselected")

    // Next Button Colors
    let nextButtonEnabledColor = UIColor(named: "colors/Primary/Light")
    let nextButtonDisabledColor = UIColor.systemGray4
    
    // Next Button Text Color
    let nextButtonEnabledTextColor = UIColor(named: "colors/Blue&Shades/blue-400")
    let nextButtonDisabledTextColor = UIColor.systemGray

    override func viewDidLoad() {
        super.viewDidLoad()

        // --- Setup for Next Button ---
        nextButton.configurationUpdateHandler = { [weak self] button in
            guard let self = self else { return }
            var config = button.configuration
            if button.isEnabled {
                config?.background.backgroundColor = self.nextButtonEnabledColor
                config?.attributedTitle?.foregroundColor = self.nextButtonEnabledTextColor
            } else {
                config?.background.backgroundColor = self.nextButtonDisabledColor
                config?.attributedTitle?.foregroundColor = self.nextButtonDisabledTextColor
            }
            button.configuration = config
        }
        
        nextButton.isEnabled = false
        
        // --- Setup for Gender Buttons ---
        for button in genderButtons {
            button.configurationUpdateHandler = { [weak self] button in
                self?.updateGenderButtonAppearance(for: button)
            }
            
            button.layer.cornerRadius = 20
            button.clipsToBounds = true
        }
    }

    @IBAction func genderButtonTapped(_ sender: UIButton) {
        for button in genderButtons {
            button.isSelected = (button == sender)
        }
        
        nextButton.isEnabled = true
    }

    private func updateGenderButtonAppearance(for button: UIButton) {
        
        var config = button.configuration ?? .filled()
        config.background.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-300")
        
        if button.tag == 1 {
            config.background.image = button.isSelected ? maleSelectedImage : maleUnselectedImage
        } else if button.tag == 2 {
            config.background.image = button.isSelected ? femaleSelectedImage : femaleUnselectedImage
        }
        
        config.background.imageContentMode = .scaleToFill
        
        if button.isSelected {
            applySelectedStyle(to: button)
        } else {
            applyUnselectedStyle(to: button)
        }

        button.configuration = config
    }
    
    private func applySelectedStyle(to button: UIButton) {
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 2.0
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 5
        
        button.clipsToBounds = true
        button.layer.masksToBounds = false
    }
    
    private func applyUnselectedStyle(to button: UIButton) {
        button.layer.borderWidth = 0
        button.layer.shadowOpacity = 0
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func backButton(_ sender: Any) {
        // Navigate back to OnboardingHealthGoalViewController (XIB)
           let goalVC = OnboardingHealthGoalViewController(nibName: "OnboardingHealthGoalViewController", bundle: nil)
           goalVC.modalPresentationStyle = .fullScreen
           present(goalVC, animated: true, completion: nil)
       }
   }
