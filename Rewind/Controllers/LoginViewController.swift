//
//  LoginViewController.swift
//  Rewind
//
//  Created by Shyam on 06/11/25.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    private var isPasswordVisible = false
       
       override func viewDidLoad() {
           super.viewDidLoad()
           setupTextFields()
           setupPasswordVisibilityToggle()
       }

       private func setupTextFields() {
           let fields = [nameTextField, passwordTextField]
           
           for field in fields {
               guard let textField = field else { continue }
               
               // White border
               textField.layer.borderColor = UIColor.white.cgColor
               textField.layer.borderWidth = 1.5
               
               // Rounded corners
               textField.layer.cornerRadius = 10
               textField.layer.masksToBounds = true
               
               // Placeholder color
               if let placeholder = textField.placeholder {
                   textField.attributedPlaceholder = NSAttributedString(
                       string: placeholder,
                       attributes: [NSAttributedString.Key.foregroundColor: UIColor(white: 1.0, alpha: 0.7)]
                   )
               }
               
               // Text color
               textField.textColor = .white
               
               // Left padding (so text doesn’t touch border)
               let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: textField.frame.height))
               textField.leftView = paddingView
               textField.leftViewMode = .always
           }
       }

       private func setupPasswordVisibilityToggle() {
           // Create the eye button
           let eyeButton = UIButton(type: .custom)
           let eyeImage = UIImage(systemName: "eye.fill")
           eyeButton.setImage(eyeImage, for: .normal)
           eyeButton.tintColor = .white
           eyeButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
           
           // Add padding using a container view
           let container = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 24))
           eyeButton.frame = CGRect(x: 8, y: 0, width: 24, height: 24) // adds 8pt left padding
           container.addSubview(eyeButton)
           
           // Assign as right view
           passwordTextField.rightView = container
           passwordTextField.rightViewMode = .always
           passwordTextField.isSecureTextEntry = true
       }

       @objc private func togglePasswordVisibility() {
           isPasswordVisible.toggle()
           passwordTextField.isSecureTextEntry = !isPasswordVisible
           
           let imageName = isPasswordVisible ? "eye.slash.fill" : "eye.fill"
           if let button = (passwordTextField.rightView)?.subviews.first as? UIButton {
               button.setImage(UIImage(systemName: imageName), for: .normal)
           }
       }
   }
