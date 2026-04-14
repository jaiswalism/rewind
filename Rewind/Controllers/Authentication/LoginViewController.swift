import UIKit
import SwiftUI

class LoginViewController: UIHostingController<LoginView> {
    
    init() {
        var loginView = LoginView()
        super.init(rootView: loginView)
        
        // Setup bridging callbacks
        let routeAfterAuthentication: (Bool) -> Void = { [weak self] isCompleted in
            DispatchQueue.main.async {
                if isCompleted {
                    self?.setRootViewController(MainTabBarController())
                } else {
                    self?.setRootViewController(OnboardingHealthGoalViewController(nibName: "OnboardingHealthGoalViewController", bundle: nil))
                }
            }
        }

        loginView.onLoginSuccess = routeAfterAuthentication
        loginView.onOAuthSuccess = routeAfterAuthentication
        
        loginView.onSignUpTapped = { [weak self] in
            self?.setRootViewController(SignupViewController())
        }
        
        loginView.onForgotPasswordTapped = { [weak self] in
            self?.setRootViewController(ForgotPasswordViewController())
        }
        
        // Reassign the configured view to the host
        self.rootView = loginView
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
