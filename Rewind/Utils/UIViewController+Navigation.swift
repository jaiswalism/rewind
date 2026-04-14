import UIKit

extension UIViewController {
    /// Helper to access the SceneDelegate and swap the root view controller.
    /// This helps flatten the navigation hierarchy and prevent deadlocks
    /// between UIKit transitions and SwiftUI's AsyncRenderer.
    func setRootViewController(_ viewController: UIViewController) {
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.setRoot(viewController)
        } else {
            // Fallback for unexpected scenarios
            viewController.modalPresentationStyle = .fullScreen
            self.present(viewController, animated: true)
        }
    }
}
