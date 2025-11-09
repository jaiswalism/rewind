//
//  ResetPasswordViewController.swift
//  Rewind
//
//  Created by Shyam on 07/11/25.
//

import UIKit

class ResetPasswordViewController: UIViewController {

    @IBOutlet var passwordField: UITextField!
    @IBOutlet var confirmPasswordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let fields = [passwordField, confirmPasswordField]
            fields.forEach { $0?.styleRoundedInput() }
    }

    @IBAction func backButton(_ sender: Any) {
        // Navigate back to OTPVerifyViewController (XIB)
               let otpVC = OTPVerifyViewController(nibName: "OTPVerifyViewController", bundle: nil)
               otpVC.modalPresentationStyle = .fullScreen
               present(otpVC, animated: true, completion: nil)
           }
       }
