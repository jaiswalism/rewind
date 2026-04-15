//
//  HelpHistoryViewController.swift
//  Rewind
//
//  Created by Shyam on 15/04/26.
//

import UIKit

/// Fourth and final onboarding step: Professional Help selection with Yes/No buttons.
class HelpHistoryViewController: OnboardingBaseViewController {

    // MARK: - Data

    private var selectedAnswer: Bool?

    // MARK: - UI Components

    private let questionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        label.numberOfLines = 0
        label.text = "Have you sought professional help for your mental health?"
        return label
    }()

    private let illustrationView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "illustrations/onboarding/Stress")
        return iv
    }()

    private let buttonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var yesButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.buttonSize = .large
        config.cornerStyle = .capsule
        config.background.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        config.attributedTitle = AttributedString("Yes", attributes: AttributeContainer([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]))
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)

        let button = UIButton(configuration: config, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = 1

        button.configurationUpdateHandler = { [weak self] btn in
            self?.updateHelpButtonAppearance(button: btn, isSelected: btn.isSelected)
        }

        button.addTarget(self, action: #selector(self.helpButtonTapped(_:)), for: .touchUpInside)

        return button
    }()

    private lazy var noButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.buttonSize = .large
        config.cornerStyle = .capsule
        config.background.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        config.attributedTitle = AttributedString("No", attributes: AttributeContainer([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]))
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)

        let button = UIButton(configuration: config, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = 2

        button.configurationUpdateHandler = { [weak self] btn in
            self?.updateHelpButtonAppearance(button: btn, isSelected: btn.isSelected)
        }

        button.addTarget(self, action: #selector(self.helpButtonTapped(_:)), for: .touchUpInside)

        return button
    }()

    private let submitButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.buttonSize = .large
        config.cornerStyle = .capsule
        config.background.backgroundColor = UIColor(named: "colors/Primary/Light")
        config.attributedTitle = AttributedString("Complete", attributes: AttributeContainer([
            .foregroundColor: UIColor(named: "colors/Blue&Shades/blue-400") ?? UIColor.systemBlue,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]))
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32)

        let button = UIButton(configuration: config, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    private var isSubmitting = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configurePageIndicator(current: 4)
        headingLabel.text = "Have you sought professional help for your mental health?"
        buildHelpButtons()
        setupSubmitButton()
    }

    // MARK: - Layout

    private func buildHelpButtons() {
        // Swap order as requested: No on left, Yes on right (or vice versa depending on addition order)
        // User asked to "exchange", so adding No first now.
        buttonsStackView.addArrangedSubview(noButton)
        buttonsStackView.addArrangedSubview(yesButton)

        mainStackView.addArrangedSubview(headingLabel)
        mainStackView.setCustomSpacing(24, after: headingLabel)
        mainStackView.addArrangedSubview(illustrationView)
        mainStackView.setCustomSpacing(32, after: illustrationView)
        mainStackView.addArrangedSubview(buttonsStackView)

        // Set width and height constraints for buttons
        NSLayoutConstraint.activate([
            illustrationView.heightAnchor.constraint(equalToConstant: 200),
            buttonsStackView.widthAnchor.constraint(equalToConstant: 280),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 56)
        ])

        mainStackView.setCustomSpacing(40, after: buttonsStackView)
        mainStackView.addArrangedSubview(submitButton)
    }

    private func updateHelpButtonAppearance(button: UIButton, isSelected: Bool) {
        guard var config = button.configuration else { return }

        if isSelected {
            config.background.backgroundColor = UIColor.white
            config.attributedTitle?.foregroundColor = UIColor(named: "colors/Blue&Shades/blue-400")
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.3
            button.layer.shadowOffset = CGSize(width: 0, height: 4)
            button.layer.shadowRadius = 5
        } else {
            config.background.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            config.attributedTitle?.foregroundColor = .white
            button.layer.shadowOpacity = 0
        }

        button.configuration = config
    }

    @objc private func helpButtonTapped(_ sender: UIButton) {
        yesButton.isSelected = (sender.tag == 1)
        noButton.isSelected = (sender.tag == 2)

        if sender.tag == 1 {
            selectedAnswer = true
        } else {
            selectedAnswer = false
        }

        // Enable submit button
        submitButton.isEnabled = true
        UIView.animate(withDuration: 0.2) {
            self.submitButton.alpha = 1.0
        }
    }

    private func setupSubmitButton() {
        submitButton.configurationUpdateHandler = { [weak self] button in
            guard let self = self else { return }
            var config = button.configuration
            if button.isEnabled {
                config?.background.backgroundColor = self.unselectedColor
                config?.attributedTitle?.foregroundColor = UIColor(named: "colors/Blue&Shades/blue-400")
            } else {
                config?.background.backgroundColor = UIColor.systemGray4
                config?.attributedTitle?.foregroundColor = UIColor.systemGray
            }
            button.configuration = config
        }

        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }

    @objc private func submitTapped() {
        guard let answer = selectedAnswer else { return }
        guard !isSubmitting else { return }

        isSubmitting = true
        OnboardingDataManager.shared.seekingProfessionalHelp = answer

        // Update button to show loading state
        var config = submitButton.configuration
        config?.attributedTitle = AttributedString("Submitting...", attributes: AttributeContainer([
            .foregroundColor: UIColor(named: "colors/Blue&Shades/blue-400") ?? UIColor.systemBlue,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]))
        submitButton.configuration = config
        submitButton.isEnabled = false

        Task {
            do {
                let _ = try await OnboardingDataManager.shared.submit()
                await MainActor.run {
                    self.setRootViewController(MainTabBarController())
                }
            } catch {
                await MainActor.run {
                    self.isSubmitting = false

                    // Reset button state
                    var config = self.submitButton.configuration
                    config?.attributedTitle = AttributedString("Complete", attributes: AttributeContainer([
                        .foregroundColor: UIColor(named: "colors/Blue&Shades/blue-400") ?? UIColor.systemBlue,
                        .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
                    ]))
                    self.submitButton.configuration = config
                    self.submitButton.isEnabled = true
                    UIView.animate(withDuration: 0.2) {
                        self.submitButton.alpha = 1.0
                    }

                    let alert = UIAlertController(
                        title: "Onboarding Failed",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}
