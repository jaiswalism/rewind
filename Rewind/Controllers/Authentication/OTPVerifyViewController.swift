import UIKit
import SwiftUI

final class OTPVerifyViewController: UIHostingController<PasswordRecoveryOTPView> {

    init(prefilledEmail: String? = nil) {
        let email = prefilledEmail ?? ""
        var view = PasswordRecoveryOTPView(email: email)
        super.init(rootView: view)

        view.onBackTapped = { [weak self] in self?.dismiss(animated: true) }

        view.onVerified = { [weak self] in
            guard let self else { return }
            let resetVC = ResetPasswordViewController()
            resetVC.modalPresentationStyle = .fullScreen
            self.present(resetVC, animated: true)
        }

        self.rootView = view
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
