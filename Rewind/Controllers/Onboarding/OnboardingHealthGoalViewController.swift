//
//  OnboardingHealthGoalViewController.swift
//  Rewind
//
//  Created by Shyam on 07/11/25.
//

import UIKit

class OnboardingHealthGoalViewController: UIViewController {

    @IBOutlet var optionButtons: [UIButton]!
    @IBOutlet weak var nextButton: UIButton!
    
    let unselectedColor = UIColor(named: "colors/Primary/Light")
    let nextButtonEnabledColor = UIColor(named: "colors/Primary/Light")
    let nextButtonDisabledColor = UIColor.systemGray4
    let selectedBackgroundColor = UIColor(named: "colors/Blue&Shades/blue-300")
    let selectedTextColor: UIColor = .white
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Set the update handler for every button in the group
        for button in optionButtons {
            button.configurationUpdateHandler = { [weak self] button in
                self?.updateButtonAppearance(for: button)
            }
        }
        
        nextButton.configurationUpdateHandler = { [weak self] button in
            guard let self = self else { return }

            var config = button.configuration
            
            // 2. Automatically change color based on 'isEnabled'
            if button.isEnabled {
                config?.background.backgroundColor = self.nextButtonEnabledColor
                config?.attributedTitle?.foregroundColor = .black // Or your enabled text color
            } else {
                config?.background.backgroundColor = self.nextButtonDisabledColor
                config?.attributedTitle?.foregroundColor = .systemGray // Darker gray for disabled text
            }
            
            // 3. Apply the changes
            button.configuration = config
        }
                
        nextButton.isEnabled = false
    }
    
    @IBAction func optionTapped(_ sender: UIButton) {
        for button in optionButtons {
            button.isSelected = (button == sender)
        }
        
        nextButton.isEnabled = true
    }
    
    private func updateButtonAppearance(for button: UIButton) {
        var config = button.configuration
        
        if button.isSelected {
            // --- SELECTED STATE ---
            
            config?.background.backgroundColor = selectedBackgroundColor
            
            config?.attributedTitle?.foregroundColor = selectedTextColor
            
            button.layer.borderColor = UIColor.white.cgColor
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.3
            button.layer.shadowOffset = CGSize(width: 0, height: 4)
            button.layer.shadowRadius = 5
            button.layer.masksToBounds = false

        } else {
            // --- NORMAL STATE (Unselected) ---
            
            config?.background.backgroundColor = unselectedColor
            
            button.layer.shadowOpacity = 0
            
            config?.attributedTitle?.foregroundColor = .black
        }
        
        button.configuration = config
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func nextButton(_ sender: Any) {
        // Navigate to OnboardingGenderViewController (XIB)
                let genderVC = OnboardingGenderViewController(nibName: "OnboardingGenderViewController", bundle: nil)
                genderVC.modalPresentationStyle = .fullScreen
                present(genderVC, animated: true, completion: nil)
            }
        }
