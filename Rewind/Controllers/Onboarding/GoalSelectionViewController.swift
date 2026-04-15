//
//  GoalSelectionViewController.swift
//  Rewind
//
//  Created by Shyam on 15/04/26.
//

import UIKit
import SwiftUI

/// First onboarding step: Health Goal Selection with pill-style buttons.
class GoalSelectionViewController: OnboardingBaseViewController {

    // MARK: - Data

    private struct HealthGoal {
        let title: String
        let icon: String?
    }

    private let goals: [HealthGoal] = [
        HealthGoal(title: "Reduce stress", icon: nil),
        HealthGoal(title: "Improve sleep", icon: nil),
        HealthGoal(title: "Build focus", icon: nil),
        HealthGoal(title: "Improve overall well-being", icon: nil),
        HealthGoal(title: "Manage anxiety", icon: nil)
    ]

    private var selectedGoalIndex: Int?

    // MARK: - UI Components

    private let pillsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fillEqually
        return stack
    }()

    private var pillButtons: [UIButton] = []

    // MARK: - Colors

    private let selectedBackgroundColor = UIColor(named: "colors/Blue&Shades/blue-300")
    private let selectedTextColor: UIColor = .white
    private let unselectedTextColor = UIColor(named: "colors/Primary/Dark")

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configurePageIndicator(current: 1)
        headingLabel.text = "What's your main health goal?"
        buildGoalPills()
        setupNextButton()
        updateNextButtonState(isEnabled: false)
    }

    // MARK: - Layout

    private func buildGoalPills() {
        for (index, goal) in goals.enumerated() {
            let button = createPillButton(goal: goal, index: index)
            pillButtons.append(button)
            pillsStackView.addArrangedSubview(button)
        }

        mainStackView.addArrangedSubview(headingLabel)
        mainStackView.setCustomSpacing(32, after: headingLabel)
        mainStackView.addArrangedSubview(pillsStackView)
        mainStackView.setCustomSpacing(40, after: pillsStackView)
        mainStackView.addArrangedSubview(nextButton)
    }

    private func createPillButton(goal: HealthGoal, index: Int) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.buttonSize = .large
        config.cornerStyle = .capsule
        config.background.backgroundColor = unselectedColor
        config.attributedTitle = AttributedString(goal.title, attributes: AttributeContainer([
            .foregroundColor: unselectedTextColor ?? UIColor.darkGray,
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]))
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)

        let button = UIButton(configuration: config, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = index

        button.configurationUpdateHandler = { [weak self] btn in
            self?.updatePillAppearance(button: btn)
        }

        button.addTarget(self, action: #selector(self.pillTapped(_:)), for: .touchUpInside)

        // Ensure buttons have a reasonable minimum width but can expand
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 280).isActive = true

        return button
    }

    private func updatePillAppearance(button: UIButton) {
        guard var config = button.configuration else { return }

        if button.isSelected {
            config.background.backgroundColor = selectedBackgroundColor
            config.attributedTitle?.foregroundColor = selectedTextColor
            button.layer.borderColor = UIColor.white.cgColor
            button.layer.borderWidth = 2.0
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.3
            button.layer.shadowOffset = CGSize(width: 0, height: 4)
            button.layer.shadowRadius = 5
        } else {
            config.background.backgroundColor = unselectedColor
            config.attributedTitle?.foregroundColor = unselectedTextColor ?? UIColor.darkGray
            button.layer.borderWidth = 0
            button.layer.shadowOpacity = 0
        }

        button.configuration = config
    }

    @objc private func pillTapped(_ sender: UIButton) {
        for button in pillButtons {
            button.isSelected = (button == sender)
        }
        selectedGoalIndex = sender.tag
        updateNextButtonState(isEnabled: true)
    }

    private func setupNextButton() {
        nextButton.configurationUpdateHandler = { [weak self] button in
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

        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    @objc private func nextTapped() {
        guard let selectedIndex = selectedGoalIndex, selectedIndex < goals.count else { return }
        OnboardingDataManager.shared.healthGoal = goals[selectedIndex].title

        navigateTo(GenderSelectionViewController())
    }
}

@objc(IntroScreenViewController)
public class IntroScreenViewController: UIViewController {

    @IBOutlet var bottomView: UIView! // Background circle
    @IBOutlet var nextBtn1: UIButton!
    
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupScrollableLayout()
    }

    private func setupScrollableLayout() {
        if contentImageView == nil {
            contentImageView = view.subviews.compactMap { $0 as? UIImageView }
                .first { $0 != bottomView && $0.image != UIImage(named: "illustrations/onboarding/bottomCircle") }
        }
        if titleLabel == nil {
            titleLabel = view.subviews.compactMap { $0 as? UILabel }.first
        }
        if progressView == nil {
            progressView = view.subviews.compactMap { $0 as? UIProgressView }.first
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        
        if let bottomView = bottomView {
            view.sendSubviewToBack(bottomView)
        }
        
        let elements: [UIView] = [contentImageView, titleLabel, progressView].compactMap { $0 }
        
        for element in elements {
            element.removeFromSuperview()
            stackView.addArrangedSubview(element)
            element.translatesAutoresizingMaskIntoConstraints = false
        }
        
        nextBtn1.removeFromSuperview()
        stackView.addArrangedSubview(nextBtn1)
        nextBtn1.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = 30
        stackView.alignment = .center
        stackView.distribution = .fill
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50),
            
            nextBtn1.widthAnchor.constraint(equalToConstant: 80),
            nextBtn1.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        if let imageView = contentImageView {
            imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 300).isActive = true
        }
    }
    
    @IBAction func finishOnboardingTapped(_ sender: Any) {
        let loginVC = LoginViewController()
        self.setRootViewController(loginVC)
          
        UserDefaults.standard.set(true, forKey: Constants.UserDefaults.hasCompletedOnboarding)
    }
}
