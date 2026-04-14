import UIKit
import SwiftUI

final class OTPVerifyViewController: UIHostingController<PasswordRecoveryOTPView> {

    init(prefilledEmail: String? = nil) {
        let email = prefilledEmail ?? ""
        var view = PasswordRecoveryOTPView(email: email)
        super.init(rootView: view)

        view.onBackTapped = { [weak self] in self?.setRootViewController(ForgotPasswordViewController()) }

        view.onVerified = { [weak self] in
            guard let self else { return }
            self.setRootViewController(ResetPasswordViewController())
        }

        self.rootView = view
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
