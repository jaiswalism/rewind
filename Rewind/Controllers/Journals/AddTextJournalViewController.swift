//
//  AddTextJournalViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

class AddTextJournalViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    // MARK: - Outlets (Connect these in your XIB)
        
        @IBOutlet weak var titleTextField: UITextField!
        @IBOutlet weak var entryTextView: UITextView!
        @IBOutlet weak var cameraButton: UIButton!
        @IBOutlet weak var uploadButton: UIButton!
        @IBOutlet var emotionButtons: [UIButton]!

        // Define active/inactive colors
        private let activeBorderColor = UIColor.white.cgColor
        private let inactiveFillColor = UIColor(named: "colors/Blue&Shades/blue-300") ?? .systemBlue
        
        // MARK: - View Lifecycle
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // 1. Assign delegates
            titleTextField.delegate = self as UITextFieldDelegate
            entryTextView.delegate = self as UITextViewDelegate
            
            setupInputs()
            setupEmotionButtons()
            
            // Ensure all components start in the inactive/unfocused state
            applyInactiveStyle(to: titleTextField)
            applyInactiveStyle(to: entryTextView)
        }
        
        // MARK: - Setup
        
        private func setupInputs() {
            
            // --- 1. Style Input Fields (Initial State) ---
            
            // Reset properties modified by styleRoundedInput() extension
            titleTextField.layer.borderWidth = 0.0
            titleTextField.setPlaceholderColor(UIColor.white.withAlphaComponent(0.6))
            
            // Title Text Field: Corner radius and color
            titleTextField.backgroundColor = inactiveFillColor
            titleTextField.layer.cornerRadius = 32
            titleTextField.clipsToBounds = true
            titleTextField.textColor = .white
            titleTextField.font = .systemFont(ofSize: 18, weight: .semibold)
            
            // Entry Text View: Corner radius and color
            entryTextView.backgroundColor = inactiveFillColor
            entryTextView.textColor = .white
            entryTextView.font = .systemFont(ofSize: 18, weight: .regular)
            entryTextView.layer.cornerRadius = 24
            entryTextView.clipsToBounds = true
            entryTextView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
            
            // Set placeholder text simulation
            if ((titleTextField.text?.isEmpty) != nil) {
                titleTextField.text = "My Day..."
            }
            
            if entryTextView.text.isEmpty {
                 entryTextView.text = "I had a bad day today, at class.... It's fine I guess...."
            }
            
            // Add the "doc.text" icon as a left accessory view to the UITextField.
            if let docIcon = UIImage(systemName: "doc.text") {
                let imageView = UIImageView(image: docIcon)
                imageView.tintColor = .white
                imageView.contentMode = .scaleAspectFit
                
                let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 48, height: 44))
                imageView.frame = CGRect(x: 16, y: 12, width: 20, height: 20)
                containerView.addSubview(imageView)
                
                titleTextField.leftView = containerView
                titleTextField.leftViewMode = .always
            }

            // --- 2. Style Buttons (Circular Border, No Background) ---
            
            // Use the inactiveFillColor as the tint for the icon to match the background color
            let buttonIconTintColor = inactiveFillColor
            
            [cameraButton, uploadButton].forEach { button in

                button?.layer.cornerRadius = (button?.frame.height ?? 48) / 2
                button?.clipsToBounds = true
                
                button?.layer.borderWidth = 1.5
                button?.layer.borderColor = UIColor.white.cgColor
                
                button?.tintColor = buttonIconTintColor
                button?.backgroundColor = .clear
            }
        }
    
    private func setupEmotionButtons() {
            for button in emotionButtons {
                button.layer.cornerRadius = (button.frame.height / 2)
                
                button.configurationUpdateHandler = { [weak self] button in
                    self?.updateEmotionButtonAppearance(for: button)
                }
                button.addTarget(self, action: #selector(emotionButtonTapped(_:)), for: .touchUpInside)
            }
            
        }
    
    private func updateEmotionButtonAppearance(for button: UIButton) {
            if button.isSelected {
                applySelectedShadow(to: button)
            } else {
                applyUnselectedShadow(to: button)
            }
        }
        
        @IBAction func emotionButtonTapped(_ sender: UIButton) {
            for button in emotionButtons {
                button.isSelected = (button == sender)
            }
            print("Emotion selected with tag: \(sender.tag)")
        }
        
        // MARK: - Shadow Implementation (Matching User Specs)
        
        private func applySelectedShadow(to button: UIButton) {
            let shadowColor = UIColor(red: 161/255.0, green: 143/255.0, blue: 255/255.0, alpha: 1).cgColor
            
            button.layer.shadowColor = shadowColor
            button.layer.shadowOffset = CGSize(width: 0, height: 0)
            button.layer.shadowOpacity = 1.0
            
            button.layer.shadowRadius = 4.0
            
            button.layer.shadowPath = UIBezierPath(ovalIn: button.bounds).cgPath
            
            button.clipsToBounds = false
            button.layer.masksToBounds = false
        }

        private func applyUnselectedShadow(to button: UIButton) {
            button.layer.shadowOpacity = 0.0
            button.layer.shadowPath = nil
            
            button.clipsToBounds = true
            button.layer.masksToBounds = true
        }
        
        // MARK: - Dynamic Style Logic (Focus/Blur)
        
        private func applyActiveStyle(to view: UIView) {
            view.layer.borderWidth = 2.0
            view.layer.borderColor = activeBorderColor
        }
        
        private func applyInactiveStyle(to view: UIView) {
            view.layer.borderWidth = 0.0
            view.layer.borderColor = UIColor.clear.cgColor
        }
        
        // MARK: - UITextField Delegate Methods (Journal Title)
        
        @objc func textFieldDidBeginEditing(_ textField: UITextField) {
            applyActiveStyle(to: textField)
        }
        
        @objc func textFieldDidEndEditing(_ textField: UITextField) {
            applyInactiveStyle(to: textField)
        }
        
        // MARK: - UITextView Delegate Methods

        @objc func textViewDidBeginEditing(_ textView: UITextView) {
            applyActiveStyle(to: textView)
        }
        
        @objc func textViewDidEndEditing(_ textView: UITextView) {
            applyInactiveStyle(to: textView)
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
