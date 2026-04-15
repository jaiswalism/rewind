import UIKit
import SwiftUI

class SignupViewController: UIHostingController<SignupView> {
    
    init() {
        var signupView = SignupView()
        super.init(rootView: signupView)
        setupCallbacks(for: &signupView)
        self.rootView = signupView
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCallbacks(for view: inout SignupView) {
        view.onSignUpSuccess = { [weak self] in
            DispatchQueue.main.async {
                self?.setRootViewController(GoalSelectionViewController())
            }
        }

        let routeAfterAuthentication: (Bool) -> Void = { [weak self] isCompleted in
            DispatchQueue.main.async {
                if isCompleted {
                    self?.setRootViewController(MainTabBarController())
                } else {
                    self?.setRootViewController(GoalSelectionViewController())
                }
            }
        }

        view.onOAuthSuccess = routeAfterAuthentication
        
        view.onSignInTapped = { [weak self] in
            DispatchQueue.main.async {
                self?.setRootViewController(LoginViewController())
            }
        }
    }
}
