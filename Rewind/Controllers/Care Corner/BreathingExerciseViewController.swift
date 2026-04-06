//
//  BreathingExerciseViewController.swift
//  Rewind
//
//  Created on 11/26/25.
//

import UIKit

class BreathingExerciseViewController: UIViewController {
    private let accentColor = UIColor(red: 0.30, green: 0.33, blue: 0.96, alpha: 1.0)
    
    // MARK: - UI Components
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        button.layer.cornerRadius = 22
        button.layer.borderWidth = 0.8
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Breathing"
        label.font = UIFont.boldSystemFont(ofSize: 34)
        label.textColor = .white
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Choose your duration and begin a calm reset."
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.85)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    private let minutesContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0.30, green: 0.33, blue: 0.96, alpha: 0.9)
        view.layer.cornerRadius = 32
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        return view
    }()
    
    private let minutesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "5"
        label.font = UIFont.boldSystemFont(ofSize: 80)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let secondsContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0.14, green: 0.16, blue: 0.25, alpha: 0.72)
        view.layer.cornerRadius = 32
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        return view
    }()
    
    private let secondsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "00"
        label.font = UIFont.boldSystemFont(ofSize: 80)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Start Breathing", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.30, green: 0.33, blue: 0.96, alpha: 1.0)
        button.layer.cornerRadius = 28
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
        
        return button
    }()

    private let patternDescriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.82)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let patternButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let sym = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let windImage = UIImage(systemName: "wind", withConfiguration: sym)
        var cfg = UIButton.Configuration.plain()
        var title = AttributedString("PATTERN: BOX 4-4-4-4")
        title.font = UIFont.boldSystemFont(ofSize: 13)
        cfg.attributedTitle = title
        cfg.image = windImage
        cfg.imagePlacement = .leading
        cfg.imagePadding = 6
        cfg.baseForegroundColor = .white
        cfg.background.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        cfg.background.cornerRadius = 20
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        button.configuration = cfg
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        return button
    }()
    
    // MARK: - Properties
    private var gradientLayer: CAGradientLayer?
    private var selectedMinutes: Int = 5
    private var selectedSeconds: Int = 0
    private var selectedPattern: BreathingPattern = .box4444
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hidesBottomBarWhenPushed = true
        setupUI()
        setupActions()
        setupGestures()
        applyTheme()
        setupTraitObservation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add gradient background
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = []
        gradient.locations = [0.0, 0.5, 1.0]
        view.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
        
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(minutesContainer)
        view.addSubview(secondsContainer)
        minutesContainer.addSubview(minutesLabel)
        secondsContainer.addSubview(secondsLabel)
        view.addSubview(patternButton)
        view.addSubview(patternDescriptionLabel)
        view.addSubview(startButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // Back Button
            backButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 26),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            // Minutes Container
            minutesContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 34),
            minutesContainer.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
            minutesContainer.widthAnchor.constraint(equalToConstant: 160),
            minutesContainer.heightAnchor.constraint(equalToConstant: 160),
            
            // Minutes Label
            minutesLabel.centerXAnchor.constraint(equalTo: minutesContainer.centerXAnchor),
            minutesLabel.centerYAnchor.constraint(equalTo: minutesContainer.centerYAnchor),
            
            // Seconds Container
            secondsContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 60),
            secondsContainer.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            secondsContainer.widthAnchor.constraint(equalToConstant: 160),
            secondsContainer.heightAnchor.constraint(equalToConstant: 160),
            
            // Seconds Label
            secondsLabel.centerXAnchor.constraint(equalTo: secondsContainer.centerXAnchor),
            secondsLabel.centerYAnchor.constraint(equalTo: secondsContainer.centerYAnchor),

            // Pattern Button
            patternButton.topAnchor.constraint(equalTo: minutesContainer.bottomAnchor, constant: 26),
            patternButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            patternButton.heightAnchor.constraint(equalToConstant: 44),
            patternButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            patternButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            // Pattern Description
            patternDescriptionLabel.topAnchor.constraint(equalTo: patternButton.bottomAnchor, constant: 10),
            patternDescriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 34),
            patternDescriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -34),
            
            // Start Button
            startButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -28),
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            startButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        startButton.addTarget(self, action: #selector(startExerciseTapped), for: .touchUpInside)
        patternButton.addTarget(self, action: #selector(patternButtonTapped), for: .touchUpInside)
    }
    
    private func setupGestures() {
        // Add swipe gestures for minutes
        let minutesSwipeUp = UISwipeGestureRecognizer(target: self, action: #selector(minutesSwipedUp))
        minutesSwipeUp.direction = .up
        minutesContainer.addGestureRecognizer(minutesSwipeUp)
        
        let minutesSwipeDown = UISwipeGestureRecognizer(target: self, action: #selector(minutesSwipedDown))
        minutesSwipeDown.direction = .down
        minutesContainer.addGestureRecognizer(minutesSwipeDown)
        
        // swipe up to increase seconds

        let secondsSwipeUp = UISwipeGestureRecognizer(target: self, action: #selector(secondsSwipedUp))
        secondsSwipeUp.direction = .up
        secondsContainer.addGestureRecognizer(secondsSwipeUp)
        
        let secondsSwipeDown = UISwipeGestureRecognizer(target: self, action: #selector(secondsSwipedDown))
        secondsSwipeDown.direction = .down
        secondsContainer.addGestureRecognizer(secondsSwipeDown)
        
        // tap to cycle through values

        let minutesTap = UITapGestureRecognizer(target: self, action: #selector(minutesTapped))
        minutesContainer.addGestureRecognizer(minutesTap)
        
        let secondsTap = UITapGestureRecognizer(target: self, action: #selector(secondsTapped))
        secondsContainer.addGestureRecognizer(secondsTap)
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func startExerciseTapped() {
        let totalSeconds = (selectedMinutes * 60) + selectedSeconds
        let animationVC = BreathingAnimationViewController(durationInSeconds: totalSeconds, pattern: selectedPattern)
        animationVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(animationVC, animated: true)
    }

    @objc private func patternButtonTapped() {
        let alert = UIAlertController(
            title: "Select Breathing Pattern",
            message: "Choose based on your goal. Focus for daytime calm, Relax for evening wind-down.",
            preferredStyle: .actionSheet
        )
        for pattern in BreathingPattern.allCases {
            let action = UIAlertAction(title: pattern.selectionTitle, style: .default) { [weak self] _ in
                self?.selectedPattern = pattern
                self?.updatePatternButton()
            }
            if pattern == selectedPattern {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func minutesSwipedUp() {
        if selectedMinutes < 60 {
            selectedMinutes += 1
            updateMinutesLabel()
        }
    }
    
    @objc private func minutesSwipedDown() {
        if selectedMinutes > 0 {
            selectedMinutes -= 1
            updateMinutesLabel()
        }
    }
    
    @objc private func secondsSwipedUp() {
        selectedSeconds = (selectedSeconds + 15) % 60
        updateSecondsLabel()
    }
    
    @objc private func secondsSwipedDown() {
        selectedSeconds = (selectedSeconds - 15 + 60) % 60
        updateSecondsLabel()
    }
    
    @objc private func minutesTapped() {
        // Cycle through common values: 1, 3, 5, 10, 15
        let commonValues = [1, 3, 5, 10, 15]
        if let currentIndex = commonValues.firstIndex(of: selectedMinutes) {
            selectedMinutes = commonValues[(currentIndex + 1) % commonValues.count]
        } else {
            selectedMinutes = 5
        }
        updateMinutesLabel()
    }
    
    @objc private func secondsTapped() {
        // Cycle through: 0, 15, 30, 45
        selectedSeconds = (selectedSeconds + 15) % 60
        updateSecondsLabel()
    }
    
    private func updateMinutesLabel() {
        UIView.transition(with: minutesLabel, duration: 0.2, options: .transitionCrossDissolve) {
            self.minutesLabel.text = "\(self.selectedMinutes)"
        }
    }
    
    private func updateSecondsLabel() {
        UIView.transition(with: secondsLabel, duration: 0.2, options: .transitionCrossDissolve) {
            self.secondsLabel.text = String(format: "%02d", self.selectedSeconds)
        }
    }

    private func updatePatternButton() {
        var config = patternButton.configuration ?? UIButton.Configuration.plain()
        var title = AttributedString("PATTERN: \(selectedPattern.displayName.uppercased())")
        title.font = UIFont.boldSystemFont(ofSize: 13)
        config.attributedTitle = title
        config.image = UIImage(systemName: "wind", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
        config.imagePlacement = .leading
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)

        let isDark = traitCollection.userInterfaceStyle != .light
        let textPrimary = isDark ? UIColor.white : UIColor.label
        config.baseForegroundColor = textPrimary
        config.background.backgroundColor = isDark ? UIColor.white.withAlphaComponent(0.12) : UIColor.systemBackground.withAlphaComponent(0.92)
        config.background.cornerRadius = 20
        patternButton.configuration = config
        patternButton.layer.borderColor = (isDark ? UIColor.white.withAlphaComponent(0.22) : UIColor.black.withAlphaComponent(0.12)).cgColor
        patternDescriptionLabel.text = selectedPattern.shortPurpose
    }

    private func applyTheme() {
        let isDark = traitCollection.userInterfaceStyle != .light
        let textPrimary = isDark ? UIColor.white : UIColor.label
        let textSecondary = isDark ? UIColor.white.withAlphaComponent(0.85) : UIColor.secondaryLabel
        let chipBackground = isDark ? UIColor.white.withAlphaComponent(0.14) : UIColor.systemBackground.withAlphaComponent(0.9)
        let chipBorder = isDark ? UIColor.white.withAlphaComponent(0.22) : UIColor.black.withAlphaComponent(0.12)

        gradientLayer?.colors = isDark
            ? [
                UIColor(red: 0.03, green: 0.05, blue: 0.16, alpha: 1.0).cgColor,
                UIColor(red: 0.08, green: 0.09, blue: 0.28, alpha: 1.0).cgColor,
                UIColor(red: 0.13, green: 0.12, blue: 0.36, alpha: 1.0).cgColor
            ]
            : [
                UIColor(red: 0.93, green: 0.95, blue: 1.00, alpha: 1.0).cgColor,
                UIColor(red: 0.88, green: 0.92, blue: 1.00, alpha: 1.0).cgColor,
                UIColor(red: 0.83, green: 0.89, blue: 1.00, alpha: 1.0).cgColor
            ]

        backButton.tintColor = textPrimary
        backButton.backgroundColor = chipBackground
        backButton.layer.borderColor = chipBorder.cgColor

        titleLabel.textColor = textPrimary
        subtitleLabel.textColor = textSecondary
        patternDescriptionLabel.textColor = isDark ? UIColor.white.withAlphaComponent(0.82) : UIColor.secondaryLabel

        minutesContainer.backgroundColor = accentColor.withAlphaComponent(isDark ? 0.92 : 0.88)
        minutesContainer.layer.borderColor = (isDark ? UIColor.white.withAlphaComponent(0.18) : UIColor.white.withAlphaComponent(0.5)).cgColor
        minutesLabel.textColor = .white

        secondsContainer.backgroundColor = isDark ? UIColor(red: 0.14, green: 0.16, blue: 0.25, alpha: 0.72) : UIColor.systemBackground.withAlphaComponent(0.92)
        secondsContainer.layer.borderColor = (isDark ? UIColor.white.withAlphaComponent(0.18) : UIColor.black.withAlphaComponent(0.10)).cgColor
        secondsLabel.textColor = textPrimary

        startButton.backgroundColor = accentColor
        startButton.layer.borderColor = (isDark ? UIColor.white.withAlphaComponent(0.14) : UIColor.black.withAlphaComponent(0.08)).cgColor
        startButton.setTitleColor(.white, for: .normal)

        updatePatternButton()
    }

    private func setupTraitObservation() {
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
                self.applyTheme()
            }
        }
    }
}
