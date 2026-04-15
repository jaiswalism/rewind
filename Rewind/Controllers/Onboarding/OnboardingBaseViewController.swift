//
//  OnboardingBaseViewController.swift
//  Rewind
//
//  Created by Shyam on 15/04/26.
//

import UIKit

/// Base view controller for all onboarding screens.
/// Provides: scroll-safe layout, gradient background, progress indicator, and navigation structure.
class OnboardingBaseViewController: UIViewController {

    // MARK: - Layout Properties

    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .onDrag
        return sv
    }()

    let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()

    // MARK: - Gradient Background

    private let gradientLayer = CAGradientLayer()

    func setupGradientBackground() {
        gradientLayer.colors = [
            UIColor(named: "colors/Blue&Shades/blue-400")?.cgColor ?? UIColor(red: 0.25, green: 0.25, blue: 0.75, alpha: 1.0).cgColor,
            UIColor(named: "colors/Blue&Shades/blue-300")?.cgColor ?? UIColor(red: 0.35, green: 0.35, blue: 0.85, alpha: 1.0).cgColor,
            UIColor(named: "colors/Blue&Shades/blue-500")?.cgColor ?? UIColor(red: 0.15, green: 0.15, blue: 0.65, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.locations = [0.0, 0.5, 1.0]
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    // MARK: - Progress Indicator

    let pageIndicator: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        return label
    }()

    func configurePageIndicator(current: Int, total: Int = 4) {
        pageIndicator.text = "\(current) of \(total)"
    }

    // MARK: - Heading Label

    let headingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Skip Button

    let skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Prefer to skip, thanks", for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return button
    }()

    // MARK: - Next Button

    // Exposed for subclasses to use in button configuration
    var unselectedColor: UIColor {
        UIColor(named: "colors/Primary/Light") ?? UIColor.systemBlue
    }

    let nextButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.buttonSize = .large
        config.cornerStyle = .capsule
        config.background.backgroundColor = UIColor(named: "colors/Primary/Light")
        config.attributedTitle = AttributedString("Next", attributes: AttributeContainer([
            .foregroundColor: UIColor(named: "colors/Blue&Shades/blue-400") ?? UIColor.systemBlue,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]))
        let button = UIButton(configuration: config, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    func updateNextButtonState(isEnabled: Bool) {
        nextButton.isEnabled = isEnabled
        UIView.animate(withDuration: 0.2) {
            self.nextButton.alpha = isEnabled ? 1.0 : 0.5
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-400")
        setupGradientBackground()
        setupScrollableLayout()
    }

    // MARK: - Layout Setup

    private func setupScrollableLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(mainStackView)

        // Add page indicator at top
        view.addSubview(pageIndicator)

        NSLayoutConstraint.activate([
            // Page indicator
            pageIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            pageIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageIndicator.heightAnchor.constraint(equalToConstant: 24),
            pageIndicator.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),

            // ScrollView pinned to safe area
            scrollView.topAnchor.constraint(equalTo: pageIndicator.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentView pinned to ScrollView's contentLayoutGuide
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // StackView pinned to ContentView with padding and centered
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            mainStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            mainStackView.widthAnchor.constraint(lessThanOrEqualToConstant: 600),
            mainStackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 24),
            mainStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -24),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
        
        // Ensure stackView expands to fill available width up to 600pt
        let widthConstraint = mainStackView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -48)
        widthConstraint.priority = .defaultLow // Allow staying at 600 if content is wider
        widthConstraint.isActive = true
    }

    // MARK: - Navigation Helpers

    func navigateTo(_ viewController: UIViewController) {
        setRootViewController(viewController)
    }
}
