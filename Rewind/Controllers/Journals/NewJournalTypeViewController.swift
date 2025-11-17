//
//  NewJournalTypeViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

class NewJournalTypeViewController: UIViewController {

    // 1. Connect your two UIButtons from the XIB to this collection
    @IBOutlet var cardButtons: [UIButton]!
    
    // 2. (Optional) Connect your "Create Journal" button
    // @IBOutlet var createJournalButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 3. Setup buttons
        for button in cardButtons {
            // Set the corner radius you used in the XIB
            button.layer.cornerRadius = 24
            button.clipsToBounds = true // Start with clipping
            
            // 4. Set the update handler
            // This will automatically call 'updateCardAppearance' when 'isSelected' changes
            button.configurationUpdateHandler = { [weak self] button in
                self?.updateCardAppearance(for: button)
            }
        }
        
        // 5. Set default selection (matches your screenshot)
        // Make sure your "Voice Journal" button in the XIB has its Tag set to 1
        if let voiceButton = cardButtons.first(where: { $0.tag == 1 }) {
            voiceButton.isSelected = true
        }
        
        // 6. Disable "Create Journal" button initially if needed
        // createJournalButton.isEnabled = true // It's already enabled in your design
    }
    
    // 7. Connect both card UIButtons to this IBAction
    @IBAction func cardTapped(_ sender: UIButton) {
        // Loop through all buttons and update their selected state
        for button in cardButtons {
            button.isSelected = (button == sender)
        }
        
        // 8. (Optional) Enable the create button
        // createJournalButton.isEnabled = true
    }
    
    // 9. This function is called automatically when 'isSelected' changes
    private func updateCardAppearance(for button: UIButton) {
        if button.isSelected {
            applySelectedStyle(to: button)
        } else {
            applyUnselectedStyle(to: button)
        }
        
        // Note: Unlike OnboardingGenderViewController, we don't need to change
        // the button's image, just its border and shadow.
    }
    
    // 10. These functions are just like the ones in OnboardingGenderViewController
    
    private func applySelectedStyle(to button: UIButton) {
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 2.0
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 5
        
        // Allow shadow to be visible outside the button's bounds
        button.clipsToBounds = false
        button.layer.masksToBounds = false
    }
    
    private func applyUnselectedStyle(to button: UIButton) {
        button.layer.borderWidth = 0
        button.layer.shadowOpacity = 0
        
        // Clip content to the rounded corners
        button.clipsToBounds = true
        button.layer.masksToBounds = true
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
