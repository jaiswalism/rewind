//
//  SignupViewController.swift
//  Rewind
//
//  Created by Shyam on 06/11/25.
//

import UIKit

class SignupViewController: UIViewController {

    
    @IBOutlet var nameInput: UITextField!
    @IBOutlet var emailPhoneField: UITextField!
    @IBOutlet var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let fields = [nameInput, emailPhoneField, passwordField]
            fields.forEach { $0?.styleRoundedInput() }

            passwordField.enablePasswordToggle()
    }
    
    @IBAction func signInButton(_ sender: Any) {
        // go to login sceren
        let loginVC = LoginViewController(nibName: "LoginViewController", bundle: nil)
        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true, completion: nil)
    }
    @IBAction func createAccountButton(_ sender: Any) {
        // Validate input
        guard let name = nameInput.text, !name.isEmpty,
              let email = emailPhoneField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields.")
            return
        }
        
        AuthService.shared.register(name: name, email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    print("Registered user: \(user.name)")
                    // Navigate to OnboardingHealthGoalViewController
                    let goalVC = OnboardingHealthGoalViewController(nibName: "OnboardingHealthGoalViewController", bundle: nil)
                    goalVC.modalPresentationStyle = .fullScreen
                    self?.present(goalVC, animated: true, completion: nil)
                    
                case .failure(let error):
                    self?.showAlert(title: "Registration Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
        }
