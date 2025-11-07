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


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
