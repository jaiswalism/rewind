//
//  ForgotPasswordViewController.swift
//  Rewind
//
//  Created by Shyam on 06/11/25.
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet var emailPhoneField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        emailPhoneField.styleRoundedInput()
    }

    @IBAction func backButton(_ sender: Any) {
        // Initialize the LoginViewController from its XIB
             let loginVC = LoginViewController(nibName: "LoginViewController", bundle: nil)
             
             // Present it full screen
             loginVC.modalPresentationStyle = .fullScreen
             present(loginVC, animated: true, completion: nil)
         }
     }
