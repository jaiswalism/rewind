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
        
        view.onSignInTapped = { [weak self] in
            DispatchQueue.main.async {
                let loginVC = LoginViewController()
                loginVC.modalPresentationStyle = .fullScreen
                self?.present(loginVC, animated: true, completion: nil)
            }
        }
    }
}
