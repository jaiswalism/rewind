import UIKit
import SwiftUI

final class ForgotPasswordViewController: UIHostingController<ForgotPasswordView> {

    init(prefilledEmail: String? = nil) {
        var view = ForgotPasswordView(prefilledEmail: prefilledEmail)
        super.init(rootView: view)

        view.onBackTapped = { [weak self] in self?.setRootViewController(LoginViewController()) }

        view.onCodeSent = { [weak self] email in
            guard let self else { return }
            self.setRootViewController(OTPVerifyViewController(prefilledEmail: email))
        }

        self.rootView = view
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
