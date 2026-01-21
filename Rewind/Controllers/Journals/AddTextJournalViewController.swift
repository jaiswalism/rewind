//
//  AddTextJournalViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit
import PhotosUI

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
        
        // MARK: - Media Properties
        private var selectedImages: [UIImage] = []
        
        private let mediaScrollView: UIScrollView = {
            let sv = UIScrollView()
            sv.showsHorizontalScrollIndicator = false
            sv.translatesAutoresizingMaskIntoConstraints = false
            sv.heightAnchor.constraint(equalToConstant: 80).isActive = true
            return sv
        }()
        
        private let mediaStack: UIStackView = {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 10
            stack.translatesAutoresizingMaskIntoConstraints = false
            return stack
        }()
    
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
            setupMediaUI()
            
            // Ensure all components start in the inactive/unfocused state
            setupCreateJournalButton()
            setupMediaButtons()
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
                
                // Bring interaction enabled to true and bring to front if needed
                button.isUserInteractionEnabled = true
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
    
    private func setupMediaUI() {
        self.view.addSubview(mediaScrollView)
        mediaScrollView.addSubview(mediaStack)
        
        NSLayoutConstraint.activate([
            mediaScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mediaScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mediaScrollView.bottomAnchor.constraint(equalTo: uploadButton.topAnchor, constant: -20),
            mediaScrollView.heightAnchor.constraint(equalToConstant: 80),
            
            mediaStack.leadingAnchor.constraint(equalTo: mediaScrollView.leadingAnchor),
            mediaStack.trailingAnchor.constraint(equalTo: mediaScrollView.trailingAnchor),
            mediaStack.topAnchor.constraint(equalTo: mediaScrollView.topAnchor),
            mediaStack.bottomAnchor.constraint(equalTo: mediaScrollView.bottomAnchor),
            mediaStack.heightAnchor.constraint(equalTo: mediaScrollView.heightAnchor)
        ])
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
        
        // ... existing delegate methods ...
        @objc func textViewDidEndEditing(_ textView: UITextView) {
            applyInactiveStyle(to: textView)
            if textView.text.isEmpty {
                textView.text = "Tell us about your day..."
                textView.textColor = UIColor.white.withAlphaComponent(0.5)
            }
        }
        
        // MARK: - Save Functionality
    
        private func setupCreateJournalButton() {
            // Since we don't have a direct outlet to the "Create Journal" button in this file (it's in the XIB),
            // we'll traverse the view hierarchy or assume it's set up in Interface Builder.
            // However, the action isn't connected in IB. Let's find it.
            
            // Recursive search helper
            func findButton(in view: UIView, withTitle title: String) -> UIButton? {
                for subview in view.subviews {
                    if let button = subview as? UIButton {
                        if button.configuration?.title == title || button.currentTitle == title {
                            return button
                        }
                    }
                    if let found = findButton(in: subview, withTitle: title) {
                        return found
                    }
                }
                return nil
            }
            
            if let createButton = findButton(in: self.view, withTitle: "Create Journal") {
                createButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
            } else {
                print("Could not find Create Journal button")
            }
        }
    
        private func setupMediaButtons() {
            cameraButton.addTarget(self, action: #selector(mediaButtonTapped), for: .touchUpInside)
            uploadButton.addTarget(self, action: #selector(mediaButtonTapped), for: .touchUpInside)
            
            // Ensure they are on top of the blur views we added in setupInputs
            cameraButton.superview?.bringSubviewToFront(cameraButton)
            uploadButton.superview?.bringSubviewToFront(uploadButton)
        }
        
        @objc private func mediaButtonTapped() {
            var config = PHPickerConfiguration()
            config.selectionLimit = 4 - selectedImages.count // Max 4 images
            config.filter = .images
            
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            present(picker, animated: true)
        }
        
        @objc private func saveButtonTapped() {
            guard let title = titleTextField.text, !title.isEmpty,
                  let content = entryTextView.text, content != "Tell us about your day...", !content.isEmpty else {
                showAlert(title: "Missing Info", message: "Please enter a title and content.")
                return
            }
            
            // Determine mood from selected emotion button
            // Assuming button tags 0...N correspond to specific moods
            var moodTags: [String] = []
            if let selectedButton = emotionButtons.first(where: { $0.isSelected }) {
                // Map tag to mood string (example mapping)
                switch selectedButton.tag {
                case 0: moodTags.append("Happy")
                case 1: moodTags.append("Calm")
                case 2: moodTags.append("Sad")
                case 3: moodTags.append("Angry")
                case 4: moodTags.append("Anxious")
                default: moodTags.append("Neutral")
                }
            }
            
            // Process Images
            var mediaUrls: [String] = []
            if !selectedImages.isEmpty {
                // Save to Documents Directory for persistence
                if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    for image in selectedImages {
                        if let data = image.jpegData(compressionQuality: 0.8) {
                            let filename = UUID().uuidString + ".jpg"
                            let fileUrl = documentsDirectory.appendingPathComponent(filename)
                            
                            do {
                                try data.write(to: fileUrl)
                                mediaUrls.append("local-image://\(filename)")
                            } catch {
                                print("Error saving image: \(error)")
                            }
                        }
                    }
                }
            }
            
            JournalService.shared.createJournal(
                title: title,
                content: content,
                type: .text,
                moodTags: moodTags,
                voiceUrl: nil,
                mediaUrls: mediaUrls, // Pass the generated URLs
                transcription: nil
            ) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        print("Journal created successfully")
                        self?.navigationController?.popViewController(animated: true)
                    case .failure(let error):
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        }
        
        private func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
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

// MARK: - PHPickerViewControllerDelegate
extension AddTextJournalViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self?.addSelectedImage(image)
                    }
                }
            }
        }
    }
    
    private func addSelectedImage(_ image: UIImage) {
        selectedImages.append(image)
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        mediaStack.addArrangedSubview(imageView)
    }
}
