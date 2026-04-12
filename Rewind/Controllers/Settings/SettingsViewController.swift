//
//  SettingsViewController.swift
//  Rewind
//

import UIKit
import SwiftUI

class SettingsViewController: UIHostingController<SettingsView> {
    private let shareMessage = "I have been using Rewind for mindful journaling and daily wellness routines. Join me on Rewind."
    private let feedbackEmail = "rewind@shyamjaiswal.in"
    private let deletionSupportEmail = "rewind@shyamjaiswal.in"

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

        view.onInviteFriends = { [weak self] in
            self?.presentInviteSheet()
        }

        view.onSubmitFeedback = { [weak self] in
            self?.openFeedbackEmail()
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

    private func presentInviteSheet() {
        let activityVC = UIActivityViewController(activityItems: [shareMessage], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(activityVC, animated: true)
    }

    private func openFeedbackEmail() {
        guard let encodedSubject = "Rewind Feedback".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "mailto:\(feedbackEmail)?subject=\(encodedSubject)") else {
            presentAlert(title: "Unable to Open Mail", message: "Please email us at \(feedbackEmail).")
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            presentAlert(title: "Unable to Open Mail", message: "Please email us at \(feedbackEmail).")
        }
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
