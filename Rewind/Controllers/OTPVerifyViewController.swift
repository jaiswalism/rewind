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


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
