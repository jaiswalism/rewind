//
//  UITextField+Style.swift
//  Rewind
//
//  Created by Shyam on 07/11/25.
//

import UIKit

extension UITextField {

    func styleRoundedInput() {
        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        textColor = .white
        setPlaceholderColor(.white.withAlphaComponent(0.6))
        setPadding(horizontal: 24, vertical: 18)
    }

    func setPlaceholderColor(_ color: UIColor) {
        guard let placeholder else { return }
        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: color]
        )
    }

    func setPadding(horizontal: CGFloat, vertical: CGFloat) {
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: horizontal, height: frame.height))
        leftView = padding
        leftViewMode = .always
    }

    func enablePasswordToggle() {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 48, height: 44))
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 44)
        container.addSubview(button)

        rightView = container
        rightViewMode = .always
        isSecureTextEntry = true
    }

    @objc private func togglePasswordVisibility() {
        isSecureTextEntry.toggle()
    }
}
