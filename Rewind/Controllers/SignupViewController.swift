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
    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        styleField(nameInput)
//    }
//
//    func styleField(_ field: UITextField) {
//        field.layer.cornerRadius = 10
//        field.layer.borderWidth = 1
//        field.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
//    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UITextField {

    func styleRoundedInput() {
        self.layer.cornerRadius = 14
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.white.cgColor
        self.textColor = .white
        self.setPlaceholderColor(.white)
        self.setPadding(horizontal: 24, vertical: 18)
    }

    func setPlaceholderColor(_ color: UIColor) {
        guard let placeholder = self.placeholder else { return }
        self.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: color]
        )
    }

    func setPadding(horizontal: CGFloat, vertical: CGFloat) {
        let paddingView = UIView(frame: CGRect(
            x: 0,
            y: 0,
            width: horizontal,
            height: self.frame.height
        ))
        self.leftView = paddingView
        self.leftViewMode = .always

        // extra right padding is handled separately for password field
        _ = UIEdgeInsets(top: vertical, left: 0, bottom: vertical, right: 0)
        self.layer.sublayerTransform = CATransform3DMakeTranslation(0, 0, 0) // ensures text doesn't clip
    }

    func enablePasswordToggle() {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)

        // Container width = icon + padding → ensures 24pt spacing to right edge
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 48, height: 44))

        // Align icon to the LEFT of the container, not centered, so padding is consistent
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 44)
        container.addSubview(button)

        self.rightView = container
        self.rightViewMode = .always
        self.isSecureTextEntry = true
    }

    @objc private func togglePasswordVisibility() {
        self.isSecureTextEntry.toggle()
    }
}

