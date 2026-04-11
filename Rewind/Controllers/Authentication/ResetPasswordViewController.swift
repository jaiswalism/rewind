import UIKit
import SwiftUI

final class ResetPasswordViewController: UIHostingController<ResetPasswordView> {

    init() {
        var view = ResetPasswordView()
        super.init(rootView: view)

        view.onDoneTapped = { [weak self] in
            guard let self else { return }
            let loginVC = LoginViewController()
            loginVC.modalPresentationStyle = .fullScreen
            self.present(loginVC, animated: true)
        }

        self.rootView = view
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
