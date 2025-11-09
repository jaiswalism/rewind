//
//  OTPVerifyViewController.swift
//  Rewind
//
//  Created by Shyam on 07/11/25.
//

import UIKit

class OTPVerifyViewController: UIViewController {

    @IBOutlet var otpInput1: UITextField!
    @IBOutlet var otpInput2: UITextField!
    @IBOutlet var otpInput3: UITextField!
    @IBOutlet var otpInput4: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let fields = [otpInput1, otpInput2, otpInput3, otpInput4]
        fields.forEach { $0?.styleRoundedInput() }
    }
    @IBAction func backButton(_ sender: Any) {
        // Navigate back to ForgotPasswordViewController (XIB)
              let forgotVC = ForgotPasswordViewController(nibName: "ForgotPasswordViewController", bundle: nil)
              forgotVC.modalPresentationStyle = .fullScreen
              present(forgotVC, animated: true, completion: nil)
          }
      }
