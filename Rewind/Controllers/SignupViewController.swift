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

        // Do any additional setup after loading the view.
        let fields = [nameInput, emailPhoneField, passwordField]
            fields.forEach { $0?.styleRoundedInput() }

            passwordField.enablePasswordToggle()
    }
    
    @IBAction func signInButton(_ sender: Any) { //  // Navigate to  // Navigate to LoginViewController (XIB-based)
        let loginVC = LoginViewController(nibName: "LoginViewController", bundle: nil)
        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true, completion: nil)
    }
}
