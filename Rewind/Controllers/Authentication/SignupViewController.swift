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
                let goalVC = OnboardingHealthGoalViewController(nibName: "OnboardingHealthGoalViewController", bundle: nil)
                goalVC.modalPresentationStyle = .fullScreen
                self?.present(goalVC, animated: true, completion: nil)
            }
        }

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

        view.onOAuthSuccess = routeAfterAuthentication
        
        view.onSignInTapped = { [weak self] in
            DispatchQueue.main.async {
                let loginVC = LoginViewController()
                loginVC.modalPresentationStyle = .fullScreen
                self?.present(loginVC, animated: true, completion: nil)
            }
        }
    }
}
