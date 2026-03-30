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

        emailPhoneField.styleRoundedInput()
    }

    @IBAction func backButton(_ sender: Any) {
        // back to login

             let loginVC = LoginViewController()
             
             loginVC.modalPresentationStyle = .fullScreen
             present(loginVC, animated: true, completion: nil)
         }
    @IBAction func sendOTPButton(_ sender: Any) {
        // Navigate to OTPVerifyViewController
                let otpVC = OTPVerifyViewController(nibName: "OTPVerifyViewController", bundle: nil)
                otpVC.modalPresentationStyle = .fullScreen
                present(otpVC, animated: true, completion: nil)
            }
        }
