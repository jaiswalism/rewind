//
//  SettingsViewController.swift
//  Rewind
//

import UIKit
import SwiftUI

class SettingsViewController: UIHostingController<SettingsView> {

    // MARK: - Init

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(rootView: SettingsView())
        setupCallbacks()
    }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Callbacks

    private func setupCallbacks() {
        var view = rootView

        view.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

        view.onPersonalInfoTapped = { [weak self] in
            guard let self else { return }
            let personalInfoVC = PersonalInformationViewController()
            navigationController?.pushViewController(personalInfoVC, animated: true)
        }

        view.onLogOut = { [weak self] in
            guard let self else { return }
            let loginVC = LoginViewController()
            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                sceneDelegate.setRoot(loginVC)
            } else {
                loginVC.modalPresentationStyle = .fullScreen
                self.present(loginVC, animated: true)
            }
        }

        rootView = view
    }
}
