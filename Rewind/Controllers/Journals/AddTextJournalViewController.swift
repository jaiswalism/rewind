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
            
            setupPremiumBackground()
            setupBackButton()
            
            // 1. Assign delegates
            titleTextField.delegate = self as UITextFieldDelegate
            entryTextView.delegate = self as UITextViewDelegate
            
            setupInputs()
            setupEmotionButtons()
            
            // Ensure all components start in the inactive/unfocused state
            // applyInactiveStyle(to: titleTextField) // Removed border based styling for glass
            // applyInactiveStyle(to: entryTextView)
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
        
        private func setupBackButton() {
            GlassBackButton.add(to: self, action: #selector(backButtonTapped))
        }
        
        @objc func backButtonTapped() {
            navigationController?.popViewController(animated: true)
        }
        
        private func setupPremiumBackground() {
            // Gradient Background
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = view.bounds
            // Deep Blue/Purple Gradient for Premium feel
            gradientLayer.colors = [
                UIColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0).cgColor,
                UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0).cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            view.layer.insertSublayer(gradientLayer, at: 0)
            
            // Add Blur Effect for Glassy feel over background (Simplified)
             let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
             let blurView = UIVisualEffectView(effect: blurEffect)
             blurView.frame = view.bounds
             blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
             
             // Ensure it's inserted above the gradient (index 0) but below everything else
             view.insertSubview(blurView, at: 1)
        }
        
        // MARK: - Setup
        
        private func setupInputs() {
            
            // --- 1. Style Input Fields (Glassmorphism) ---
            
            // Common Glass Style Helper
            func applyGlassStyle(to view: UIView, cornerRadius: CGFloat) {
                view.backgroundColor = .clear // Important for glass
                view.layer.cornerRadius = cornerRadius
                view.clipsToBounds = true
                view.layer.borderWidth = 1.0
                view.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
                
                // Add blur view behind
                let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
                let blurView = UIVisualEffectView(effect: blurEffect)
                blurView.frame = view.bounds
                blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                blurView.isUserInteractionEnabled = false // Let touches pass through
                view.insertSubview(blurView, at: 0)
            }
            
            // Title Text Field
            applyGlassStyle(to: titleTextField, cornerRadius: 24)
            titleTextField.textColor = .white
            titleTextField.font = .systemFont(ofSize: 20, weight: .bold) // Premium font
            titleTextField.setPlaceholderColor(UIColor.white.withAlphaComponent(0.5))

            
            // Entry Text View
            applyGlassStyle(to: entryTextView, cornerRadius: 24)
            entryTextView.textColor = .white.withAlphaComponent(0.9)
            entryTextView.font = .systemFont(ofSize: 17, weight: .medium)
            entryTextView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            
            // Set placeholder text simulation
            titleTextField.attributedPlaceholder = NSAttributedString(
                string: "My Day...",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
            )
            titleTextField.text = "" // Ensure empty initially
            
            // TextView placeholder logic handled via delegate or initial text color
            entryTextView.text = "Tell us about your day..."
            entryTextView.textColor = UIColor.white.withAlphaComponent(0.5) // Placeholder color
            
            // Add the "doc.text" icon as a left accessory view to the UITextField.
            if let docIcon = UIImage(systemName: "pencil") {
                let imageView = UIImageView(image: docIcon)
                imageView.tintColor = .white.withAlphaComponent(0.7)
                imageView.contentMode = .scaleAspectFit
                
                let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
                imageView.frame = CGRect(x: 18, y: 15, width: 20, height: 20)
                containerView.addSubview(imageView)
                
                titleTextField.leftView = containerView
                titleTextField.leftViewMode = .always
            }

            // --- 2. Style Buttons (Floating Premium) ---
            
            [cameraButton, uploadButton].forEach { button in
                guard let button = button else { return }
                button.layer.cornerRadius = button.frame.height / 2
                button.clipsToBounds = true
                
                // Glass button style
                button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
                button.layer.borderWidth = 1.0
                button.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
                button.tintColor = .white
                
                // Add blur to button
                 let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
                 blur.frame = button.bounds
                 blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                 blur.isUserInteractionEnabled = false
                 button.insertSubview(blur, at: 0)
            }
        }
    
    private func setupEmotionButtons() {
            for button in emotionButtons {
                button.layer.cornerRadius = (button.frame.height / 2)
                
                button.configurationUpdateHandler = { [weak self] button in
                    self?.updateEmotionButtonAppearance(for: button)
                }
                button.addTarget(self, action: #selector(emotionButtonTapped(_:)), for: .touchUpInside)
                
                // Ensure initial state
                updateEmotionButtonAppearance(for: button)
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
                // Trigger update immediately
                updateEmotionButtonAppearance(for: button)
            }
            print("Emotion selected with tag: \(sender.tag)")
        }
        
        // MARK: - Shadow Implementation (Premium Glow)
        
        private func applySelectedShadow(to button: UIButton) {
            // Enhanced "Glow" effect
            let shadowColor = UIColor(red: 161/255.0, green: 143/255.0, blue: 255/255.0, alpha: 1).cgColor
            
            button.layer.shadowColor = shadowColor
            button.layer.shadowOffset = CGSize(width: 0, height: 0)
            button.layer.shadowOpacity = 1.0 // Full opacity for glow
            button.layer.shadowRadius = 15.0 // Increased radius for spread
            
            // Removed border "box" as requested
            button.layer.borderColor = UIColor.clear.cgColor
            button.layer.borderWidth = 0.0
            
            button.clipsToBounds = false
            button.layer.masksToBounds = false
        }

        private func applyUnselectedShadow(to button: UIButton) {
            button.layer.shadowOpacity = 0.0
            button.layer.shadowPath = nil
            button.layer.borderColor = UIColor.clear.cgColor
            button.layer.borderWidth = 0.0
            
            button.clipsToBounds = true
            button.layer.masksToBounds = true
        }
        
        // MARK: - Dynamic Style Logic (Focus/Blur)
        
        private func applyActiveStyle(to view: UIView) {
            view.layer.borderWidth = 2.0
            view.layer.borderColor = activeBorderColor
        }
        
        private func applyInactiveStyle(to view: UIView) {
            view.layer.borderWidth = 1.0
            view.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
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
            if textView.text == "Tell us about your day..." {
                textView.text = ""
                textView.textColor = .white.withAlphaComponent(0.9)
            }
        }
        
        @objc func textViewDidEndEditing(_ textView: UITextView) {
            applyInactiveStyle(to: textView)
            if textView.text.isEmpty {
                textView.text = "Tell us about your day..."
                textView.textColor = UIColor.white.withAlphaComponent(0.5)
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
