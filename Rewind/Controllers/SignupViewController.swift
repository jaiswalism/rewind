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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
