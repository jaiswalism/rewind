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
                    let mainTabVC = MainTabBarController()
                    if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                        sceneDelegate.setRoot(mainTabVC)
                    } else {
                        mainTabVC.modalPresentationStyle = .fullScreen
                        self?.present(mainTabVC, animated: true)
                    }
                } else {
                    let goalVC = OnboardingHealthGoalViewController(nibName: "OnboardingHealthGoalViewController", bundle: nil)
                    goalVC.modalPresentationStyle = .fullScreen
                    self?.present(goalVC, animated: true)
                }
            }
        }

        loginView.onLoginSuccess = routeAfterAuthentication
        loginView.onOAuthSuccess = routeAfterAuthentication
        
        loginView.onSignUpTapped = { [weak self] in
            let signupVC = SignupViewController()
            signupVC.modalPresentationStyle = .fullScreen
            self?.present(signupVC, animated: true, completion: nil)
        }
        
        loginView.onForgotPasswordTapped = { [weak self] in
            let forgetVC = ForgotPasswordViewController(nibName: "ForgotPasswordViewController", bundle: nil)
            forgetVC.modalPresentationStyle = .fullScreen
            self?.present(forgetVC, animated: true, completion: nil)
        }
        
        // Reassign the configured view to the host
        self.rootView = loginView
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
