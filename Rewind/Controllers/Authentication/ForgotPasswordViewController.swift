import UIKit
import SwiftUI

final class ForgotPasswordViewController: UIHostingController<ForgotPasswordView> {

    init(prefilledEmail: String? = nil) {
        var view = ForgotPasswordView(prefilledEmail: prefilledEmail)
        super.init(rootView: view)

        view.onBackTapped = { [weak self] in self?.dismiss(animated: true) }

        view.onCodeSent = { [weak self] email in
            guard let self else { return }
            let otpController = OTPVerifyViewController(prefilledEmail: email)
            otpController.modalPresentationStyle = .fullScreen
            self.present(otpController, animated: true)
        }

        self.rootView = view
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
