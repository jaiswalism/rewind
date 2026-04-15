//
//  GenderSelectionViewController.swift
//  Rewind
//
//  Created by Shyam on 15/04/26.
//

import UIKit

/// Second onboarding step: Gender Selection with card-style buttons.
/// Reuses the same gender selection UI from the original XIB implementation.
class GenderSelectionViewController: OnboardingBaseViewController {

    // MARK: - Data

    private enum GenderOption {
        case male
        case female

        var tag: Int {
            switch self {
            case .male: return 1
            case .female: return 2
            }
        }

        var title: String {
            switch self {
            case .male: return "I am Male"
            case .female: return "I am Female"
            }
        }

        var symbolName: String {
            switch self {
            case .male: return "mars"
            case .female: return "venus"
            }
        }

        var selectedImage: UIImage? {
            switch self {
            case .male: return UIImage(named: "illustrations/onboarding/Male Selected")
            case .female: return UIImage(named: "illustrations/onboarding/Female Selected")
            }
        }

        var unselectedImage: UIImage? {
            switch self {
            case .male: return UIImage(named: "illustrations/onboarding/Male Unselected")
            case .female: return UIImage(named: "illustrations/onboarding/Female Unselected")
            }
        }
    }

    private let options: [GenderOption] = [.male, .female]
    private var selectedGender: GenderOption?

    // MARK: - UI Components

    private let cardsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fillEqually
        return stack
    }()

    private var genderButtons: [UIButton] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configurePageIndicator(current: 2)
        headingLabel.text = "What's your gender?"
        styleSkipButton()
        buildGenderCards()
        setupSkipButton()
        setupNextButton()
        updateNextButtonState(isEnabled: false)
    }

    private func styleSkipButton() {
        var config = UIButton.Configuration.filled()
        config.buttonSize = .medium
        config.cornerStyle = .capsule
        config.background.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        config.attributedTitle = AttributedString("Prefer to skip, thanks", attributes: AttributeContainer([
            .foregroundColor: UIColor.white.withAlphaComponent(0.8),
            .font: UIFont.systemFont(ofSize: 15, weight: .medium)
        ]))
        skipButton.configuration = config
    }

    // MARK: - Layout

    private func buildGenderCards() {
        for option in options {
            let button = createGenderCard(option: option)
            genderButtons.append(button)
            cardsStackView.addArrangedSubview(button)
        }

        mainStackView.addArrangedSubview(headingLabel)
        mainStackView.setCustomSpacing(32, after: headingLabel)
        mainStackView.addArrangedSubview(cardsStackView)

        // Set width and height constraints for cards to ensure they don't look narrow
        for button in genderButtons {
            button.widthAnchor.constraint(equalToConstant: 300).isActive = true
            button.heightAnchor.constraint(equalToConstant: 160).isActive = true
        }
        
        mainStackView.setCustomSpacing(40, after: cardsStackView)
        mainStackView.addArrangedSubview(skipButton)
        mainStackView.setCustomSpacing(16, after: skipButton)
        mainStackView.addArrangedSubview(nextButton)
    }

    private func createGenderCard(option: GenderOption) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-200")
        config.background.image = option.unselectedImage
        config.background.imageContentMode = .scaleToFill
        config.cornerStyle = .medium

        let button = UIButton(configuration: config, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = option.tag
        button.layer.cornerRadius = 20
        button.clipsToBounds = true

        // Add title label at top-left
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = option.title
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .left
        button.addSubview(titleLabel)

        // Add symbol image at bottom-left
        let symbolImageView = UIImageView()
        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.image = UIImage(systemName: option.symbolName)
        symbolImageView.tintColor = .white
        symbolImageView.contentMode = .scaleAspectFit
        button.addSubview(symbolImageView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: button.topAnchor, constant: 20),
            
            symbolImageView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 20),
            symbolImageView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -20),
            symbolImageView.widthAnchor.constraint(equalToConstant: 24),
            symbolImageView.heightAnchor.constraint(equalToConstant: 24)
        ])

        button.configurationUpdateHandler = { [weak self] btn in
            self?.updateGenderCardAppearance(button: btn, option: option)
        }

        button.addTarget(self, action: #selector(self.genderCardTapped(_:)), for: .touchUpInside)

        return button
    }

    private func updateGenderCardAppearance(button: UIButton, option: GenderOption) {
        guard var config = button.configuration else { return }

        config.background.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-200")
        config.background.image = button.isSelected ? option.selectedImage : option.unselectedImage
        config.background.imageContentMode = .scaleAspectFill

        if button.isSelected {
            button.layer.borderColor = UIColor.white.cgColor
            button.layer.borderWidth = 2.0
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.3
            button.layer.shadowOffset = CGSize(width: 0, height: 4)
            button.layer.shadowRadius = 5
            button.clipsToBounds = true
            button.layer.masksToBounds = false
        } else {
            button.layer.borderWidth = 0
            button.layer.shadowOpacity = 0
        }

        button.configuration = config
    }

    @objc private func genderCardTapped(_ sender: UIButton) {
        for button in genderButtons {
            button.isSelected = (button == sender)
        }

        // Determine which gender was selected
        if sender.tag == 1 {
            selectedGender = .male
        } else if sender.tag == 2 {
            selectedGender = .female
        }

        updateNextButtonState(isEnabled: true)
    }

    private func setupSkipButton() {
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
    }

    @objc private func skipTapped() {
        OnboardingDataManager.shared.gender = "prefer_not_to_say"
        navigateTo(AgeSelectionViewController())
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
        guard let gender = selectedGender else { return }
        let genderString: String
        switch gender {
        case .male:
            genderString = "male"
        case .female:
            genderString = "female"
        }
        OnboardingDataManager.shared.gender = genderString

        navigateTo(AgeSelectionViewController())
    }
}
