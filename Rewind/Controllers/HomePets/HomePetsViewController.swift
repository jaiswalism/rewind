import UIKit
import SceneKit
import Combine
import Foundation
import SwiftUI

class HomePetsViewController: UIHostingController<HomePetsView> {
    
    // MARK: - Init
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(rootView: HomePetsView())
        setupCallbacks()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup Callbacks
    
    private func setupCallbacks() {
        // Bridge the SwiftUI actions to standard navigation logic
        var connectedView = self.rootView

        connectedView.onSettingsTapped = { [weak self] in
            guard let self = self else { return }
            let settingsVC = SettingsViewController()
            if let navController = self.navigationController {
                navController.pushViewController(settingsVC, animated: true)
            } else {
                let navController = UINavigationController(rootViewController: settingsVC)
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true)
            }
        }

        connectedView.onNotificationsTapped = { [weak self] in
            guard let self = self else { return }
            let notificationsVC = NotificationsViewController()
            if let navController = self.navigationController {
                navController.pushViewController(notificationsVC, animated: true)
            } else {
                let navController = UINavigationController(rootViewController: notificationsVC)
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true)
            }
        }

        // NOTE: Talk is now handled inline inside HomePetsView – no navigation needed.

        // Apply the updated view back to hosting controller
        self.rootView = connectedView
    }
}
