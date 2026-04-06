//
//  ExerciseCompletedViewController.swift
//  Rewind
//
//  Created on 11/26/25.
//

import UIKit

class ExerciseCompletedViewController: UIViewController {
    private let accentColor = UIColor(red: 0.30, green: 0.33, blue: 0.96, alpha: 1.0)
    private var gradientLayer: CAGradientLayer?
    private var didRunEntryAnimation = false

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear 
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Exercise\nCompleted"
        label.font = UIFont.boldSystemFont(ofSize: 40)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Task is recorded.\nYou can continue your activity now!"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.alpha = 0.9
        return label
    }()

    private let resultBadge: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 34
        view.layer.borderWidth = 1
        view.clipsToBounds = true
        return view
    }()

    private let resultIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let durationBadge: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        view.layer.borderWidth = 0.8
        view.layer.cornerRadius = 22
        return view
    }()
    
    private let durationIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        imageView.image = UIImage(systemName: "clock", withConfiguration: config)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "DURATION: 25M"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let durationStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }()

    private let pawsBadge: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        view.layer.borderWidth = 0.8
        view.layer.cornerRadius = 22
        return view
    }()
    
    private let pawsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "100 PAWS CREDITED"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let illustrationImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "illustrations/careCorner/ExCompleteBottomBG")
        imageView.clipsToBounds = true
        return imageView
    }()

    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Back to Care Corner", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.30, green: 0.33, blue: 0.96, alpha: 1.0)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
        button.layer.cornerRadius = 28
        return button
    }()

    private let duration: String
    private let pawsEarned: Int
    private let activityName: String
    private let rewarded: Bool
    private let minimumRewardSeconds: Int
    private var isNavigatingBack = false

    init(
        duration: String,
        pawsEarned: Int = 100,
        activityName: String = "Exercise",
        rewarded: Bool = true,
        minimumRewardSeconds: Int = 60
    ) {
        self.duration = duration
        self.pawsEarned = pawsEarned
        self.activityName = activityName
        self.rewarded = rewarded
        self.minimumRewardSeconds = minimumRewardSeconds
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.duration = "5M"
        self.pawsEarned = 100
        self.activityName = "Exercise"
        self.rewarded = true
        self.minimumRewardSeconds = 60
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // hiding nav bar for immersion

        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupUI()
        setupActions()
        updateLabels()
        applyTheme()
        setupTraitObservation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateEntryIfNeeded()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = []
        gradient.locations = [0.0, 0.55, 1.0]
        view.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
        
        view.insertSubview(illustrationImageView, at: 0)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        view.addSubview(backButton)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(resultBadge)
        resultBadge.addSubview(resultIconView)

        durationStackView.addArrangedSubview(durationIcon)
        durationStackView.addArrangedSubview(durationLabel)
        durationBadge.addSubview(durationStackView)
        contentView.addSubview(durationBadge)

        pawsBadge.addSubview(pawsLabel)
        contentView.addSubview(pawsBadge)
        
        setupConstraints()
        prepareForEntryAnimation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
    }

    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        
        // Constraints for the primary screen structure
        NSLayoutConstraint.activate([
            illustrationImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            illustrationImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            illustrationImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            illustrationImageView.heightAnchor.constraint(equalToConstant: 480),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: backButton.topAnchor, constant: -20),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -30),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            resultBadge.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 26),
            resultBadge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            resultBadge.widthAnchor.constraint(equalToConstant: 68),
            resultBadge.heightAnchor.constraint(equalToConstant: 68),

            resultIconView.centerXAnchor.constraint(equalTo: resultBadge.centerXAnchor),
            resultIconView.centerYAnchor.constraint(equalTo: resultBadge.centerYAnchor),
            resultIconView.widthAnchor.constraint(equalToConstant: 30),
            resultIconView.heightAnchor.constraint(equalToConstant: 30),
            
            durationBadge.topAnchor.constraint(equalTo: resultBadge.bottomAnchor, constant: 24),
            durationBadge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            durationBadge.heightAnchor.constraint(equalToConstant: 44),
            durationBadge.widthAnchor.constraint(equalToConstant: 200),
            
            durationStackView.centerXAnchor.constraint(equalTo: durationBadge.centerXAnchor),
            durationStackView.centerYAnchor.constraint(equalTo: durationBadge.centerYAnchor),

            pawsBadge.topAnchor.constraint(equalTo: durationBadge.bottomAnchor, constant: 12),
            pawsBadge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            pawsBadge.heightAnchor.constraint(equalToConstant: 44),
            pawsBadge.widthAnchor.constraint(equalToConstant: 220),
            
            pawsLabel.centerXAnchor.constraint(equalTo: pawsBadge.centerXAnchor),
            pawsLabel.centerYAnchor.constraint(equalTo: pawsBadge.centerYAnchor),

            backButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -30),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            backButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            backButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    private func updateLabels() {
        titleLabel.text = "\(activityName)\nCompleted"
        durationLabel.text = "DURATION: \(duration)"

        if rewarded {
            subtitleLabel.text = "Strong finish. Your \(activityName.lowercased()) session is saved and rewards are now in your balance."
            pawsLabel.text = "+\(pawsEarned) PAWS CREDITED"
        } else {
            let minMinutes = max(1, minimumRewardSeconds / 60)
            subtitleLabel.text = "Session saved. Keep going for at least \(minMinutes) minute\(minMinutes == 1 ? "" : "s") to unlock paws next time."
            pawsLabel.text = "0 PAWS THIS ROUND"
        }
    }

    private func prepareForEntryAnimation() {
        let animatedViews: [UIView] = [
            titleLabel,
            subtitleLabel,
            resultBadge,
            durationBadge,
            pawsBadge,
            backButton
        ]

        animatedViews.forEach {
            $0.alpha = 0
            $0.transform = CGAffineTransform(translationX: 0, y: 18)
        }
    }

    private func animateEntryIfNeeded() {
        guard !didRunEntryAnimation else { return }
        didRunEntryAnimation = true

        let animatedViews: [UIView] = [
            titleLabel,
            subtitleLabel,
            resultBadge,
            durationBadge,
            pawsBadge,
            backButton
        ]

        if UIAccessibility.isReduceMotionEnabled {
            animatedViews.forEach {
                $0.alpha = 1
                $0.transform = .identity
            }
            return
        }

        for (index, item) in animatedViews.enumerated() {
            UIView.animate(
                withDuration: 0.46,
                delay: 0.05 + (Double(index) * 0.06),
                usingSpringWithDamping: 0.86,
                initialSpringVelocity: 0.2,
                options: [.curveEaseOut],
                animations: {
                    item.alpha = 1
                    item.transform = .identity
                }
            )
        }
    }

    private func applyTheme() {
        let isDark = traitCollection.userInterfaceStyle != .light
        let textPrimary = isDark ? UIColor.white : UIColor.label
        let textSecondary = isDark ? UIColor.white.withAlphaComponent(0.9) : UIColor.secondaryLabel
        let cardBackground = isDark ? UIColor.white.withAlphaComponent(0.14) : UIColor.systemBackground.withAlphaComponent(0.94)
        let cardBorder = isDark ? UIColor.white.withAlphaComponent(0.25) : UIColor.black.withAlphaComponent(0.10)
        let badgeBackground = isDark ? UIColor.white.withAlphaComponent(0.14) : UIColor.white.withAlphaComponent(0.96)
        let badgeBorder = isDark ? UIColor.white.withAlphaComponent(0.24) : UIColor.black.withAlphaComponent(0.10)

        gradientLayer?.colors = isDark
            ? [
                UIColor(red: 0.03, green: 0.05, blue: 0.16, alpha: 1.0).cgColor,
                UIColor(red: 0.09, green: 0.10, blue: 0.30, alpha: 1.0).cgColor,
                UIColor(red: 0.14, green: 0.12, blue: 0.36, alpha: 1.0).cgColor
            ]
            : [
                UIColor(red: 0.96, green: 0.97, blue: 1.00, alpha: 1.0).cgColor,
                UIColor(red: 0.91, green: 0.94, blue: 1.00, alpha: 1.0).cgColor,
                UIColor(red: 0.85, green: 0.90, blue: 1.00, alpha: 1.0).cgColor
            ]

        illustrationImageView.alpha = isDark ? 1.0 : 0.20

        titleLabel.textColor = textPrimary
        subtitleLabel.textColor = textSecondary
        durationLabel.textColor = textPrimary
        pawsLabel.textColor = textPrimary
        durationIcon.tintColor = textPrimary

        durationBadge.backgroundColor = cardBackground
        durationBadge.layer.borderColor = cardBorder.cgColor
        pawsBadge.backgroundColor = cardBackground
        pawsBadge.layer.borderColor = cardBorder.cgColor

        resultBadge.backgroundColor = badgeBackground
        resultBadge.layer.borderColor = badgeBorder.cgColor
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        if rewarded {
            resultIconView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: symbolConfig)
            resultIconView.tintColor = accentColor
        } else {
            resultIconView.image = UIImage(systemName: "clock.badge.exclamationmark.fill", withConfiguration: symbolConfig)
            resultIconView.tintColor = isDark ? UIColor.white.withAlphaComponent(0.92) : UIColor(red: 0.30, green: 0.33, blue: 0.96, alpha: 1.0)
        }

        backButton.backgroundColor = accentColor
        backButton.setTitleColor(.white, for: .normal)
    }

    private func setupTraitObservation() {
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
                self.applyTheme()
            }
        }
    }

    @objc private func backButtonTapped() {
        guard !isNavigatingBack else { return }
        isNavigatingBack = true
        backButton.isEnabled = false

        if let navigationController = navigationController {
            for viewController in navigationController.viewControllers.reversed() {
                if viewController is CareCornerViewController {
                    navigationController.popToViewController(viewController, animated: true)
                    return
                }
            }
            navigationController.popToRootViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
