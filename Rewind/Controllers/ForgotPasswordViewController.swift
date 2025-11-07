//
//  ForgotPasswordViewController.swift
//  Rewind
//
//  Created by Shyam on 06/11/25.
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var enterEmailPhone: UITextField!
    override func viewDidLoad() {
            super.viewDidLoad()
            styleTextField()
        }

        private func styleTextField() {
            // White border
            enterEmailPhone.layer.borderColor = UIColor.white.cgColor
            enterEmailPhone.layer.borderWidth = 1.5
            enterEmailPhone.layer.cornerRadius = 10
            enterEmailPhone.layer.masksToBounds = true

            // Add left and right padding
            let paddingViewLeft = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: enterEmailPhone.frame.height))
            let paddingViewRight = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: enterEmailPhone.frame.height))
            enterEmailPhone.leftView = paddingViewLeft
            enterEmailPhone.rightView = paddingViewRight
            enterEmailPhone.leftViewMode = .always
            enterEmailPhone.rightViewMode = .always

            // Optional — make text color and placeholder visually cleaner
            enterEmailPhone.textColor = .white
            if let placeholder = enterEmailPhone.placeholder {
                enterEmailPhone.attributedPlaceholder = NSAttributedString(
                    string: placeholder,
                    attributes: [.foregroundColor: UIColor(white: 1.0, alpha: 0.6)]
                )
            }

            // Optional — slightly translucent background
            enterEmailPhone.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        }
    }
