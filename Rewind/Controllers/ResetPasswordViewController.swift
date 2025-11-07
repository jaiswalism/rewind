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
        passwordField.enablePasswordToggle()
        confirmPasswordField.enablePasswordToggle()
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
