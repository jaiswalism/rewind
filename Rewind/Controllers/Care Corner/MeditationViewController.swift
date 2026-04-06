import UIKit

class MeditationViewController: UIViewController {
    private let accentColor = UIColor(red: 0.30, green: 0.33, blue: 0.96, alpha: 1.0)
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
        label.text = "Meditation"
        label.font = UIFont.boldSystemFont(ofSize: 34)
        label.textColor = .white
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Set your session length and audio ambience."
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
        label.text = "25"
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

    private let soundButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let sym = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let speakerImage = UIImage(systemName: "speaker.wave.2.fill", withConfiguration: sym)
        var cfg = UIButton.Configuration.plain()
        var soundTitle = AttributedString("SOUND: CHIRPING BIRDS")
        soundTitle.font = UIFont.boldSystemFont(ofSize: 13)
        cfg.attributedTitle = soundTitle
        cfg.image = speakerImage
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

    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Start Meditation", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.30, green: 0.33, blue: 0.96, alpha: 1.0)
        button.layer.cornerRadius = 28
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
        return button
    }()

    private var gradientLayer: CAGradientLayer?
    private var selectedMinutes: Int = 25
    private var selectedSeconds: Int = 0
    private var selectedSound: String = "Chirping Birds"

    private let soundOptions = ["Chirping Birds", "Ocean Waves", "Rain", "Forest", "White Noise", "Silence"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupGestures()
        applyTheme()
        updateSoundButton()
        setupTraitObservation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
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
        view.addSubview(soundButton)
        view.addSubview(startButton)
        setupConstraints()
    }

    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 26),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            minutesContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 34),
            minutesContainer.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
            minutesContainer.widthAnchor.constraint(equalToConstant: 160),
            minutesContainer.heightAnchor.constraint(equalToConstant: 160),
            minutesLabel.centerXAnchor.constraint(equalTo: minutesContainer.centerXAnchor),
            minutesLabel.centerYAnchor.constraint(equalTo: minutesContainer.centerYAnchor),
            secondsContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 34),
            secondsContainer.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            secondsContainer.widthAnchor.constraint(equalToConstant: 160),
            secondsContainer.heightAnchor.constraint(equalToConstant: 160),
            secondsLabel.centerXAnchor.constraint(equalTo: secondsContainer.centerXAnchor),
            secondsLabel.centerYAnchor.constraint(equalTo: secondsContainer.centerYAnchor),
            soundButton.topAnchor.constraint(equalTo: minutesContainer.bottomAnchor, constant: 26),
            soundButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            soundButton.heightAnchor.constraint(equalToConstant: 44),
            soundButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            soundButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            startButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -28),
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            startButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        startButton.addTarget(self, action: #selector(startExerciseTapped), for: .touchUpInside)
        soundButton.addTarget(self, action: #selector(soundButtonTapped), for: .touchUpInside)
    }

    private func setupGestures() {
        let minutesSwipeUp = UISwipeGestureRecognizer(target: self, action: #selector(minutesSwipedUp))
        minutesSwipeUp.direction = .up
        minutesContainer.addGestureRecognizer(minutesSwipeUp)
        let minutesSwipeDown = UISwipeGestureRecognizer(target: self, action: #selector(minutesSwipedDown))
        minutesSwipeDown.direction = .down
        minutesContainer.addGestureRecognizer(minutesSwipeDown)
        let secondsSwipeUp = UISwipeGestureRecognizer(target: self, action: #selector(secondsSwipedUp))
        secondsSwipeUp.direction = .up
        secondsContainer.addGestureRecognizer(secondsSwipeUp)
        let secondsSwipeDown = UISwipeGestureRecognizer(target: self, action: #selector(secondsSwipedDown))
        secondsSwipeDown.direction = .down
        secondsContainer.addGestureRecognizer(secondsSwipeDown)
        let minutesTap = UITapGestureRecognizer(target: self, action: #selector(minutesTapped))
        minutesContainer.addGestureRecognizer(minutesTap)
        let secondsTap = UITapGestureRecognizer(target: self, action: #selector(secondsTapped))
        secondsContainer.addGestureRecognizer(secondsTap)
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func startExerciseTapped() {
        let totalSeconds = (selectedMinutes * 60) + selectedSeconds
        let sessionVC = MeditationSessionViewController(durationInSeconds: totalSeconds, soundName: selectedSound)
        sessionVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(sessionVC, animated: true)
    }

    @objc private func soundButtonTapped() {
        let alert = UIAlertController(title: "Select Sound", message: nil, preferredStyle: .actionSheet)
        for sound in soundOptions {
            let action = UIAlertAction(title: sound, style: .default) { [weak self] _ in
                self?.selectedSound = sound
                self?.updateSoundButton()
            }
            if sound == selectedSound {
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
        let commonValues = [5, 10, 15, 20, 25, 30]
        if let currentIndex = commonValues.firstIndex(of: selectedMinutes) {
            selectedMinutes = commonValues[(currentIndex + 1) % commonValues.count]
        } else {
            selectedMinutes = 25
        }
        updateMinutesLabel()
    }

    @objc private func secondsTapped() {
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

    private func updateSoundButton() {
        var config = soundButton.configuration ?? UIButton.Configuration.plain()
        var soundTitle = AttributedString("SOUND: \(selectedSound.uppercased())")
        soundTitle.font = UIFont.boldSystemFont(ofSize: 13)
        config.attributedTitle = soundTitle
        config.image = UIImage(systemName: "speaker.wave.2.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
        config.imagePlacement = .leading
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)

        let isDark = traitCollection.userInterfaceStyle != .light
        let textPrimary = isDark ? UIColor.white : UIColor.label
        config.baseForegroundColor = textPrimary
        config.background.backgroundColor = isDark ? UIColor.white.withAlphaComponent(0.12) : UIColor.systemBackground.withAlphaComponent(0.92)
        config.background.cornerRadius = 20
        soundButton.configuration = config
        soundButton.layer.borderColor = (isDark ? UIColor.white.withAlphaComponent(0.22) : UIColor.black.withAlphaComponent(0.12)).cgColor
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

        minutesContainer.backgroundColor = accentColor.withAlphaComponent(isDark ? 0.92 : 0.88)
        minutesContainer.layer.borderColor = (isDark ? UIColor.white.withAlphaComponent(0.18) : UIColor.white.withAlphaComponent(0.5)).cgColor
        minutesLabel.textColor = .white

        secondsContainer.backgroundColor = isDark ? UIColor(red: 0.14, green: 0.16, blue: 0.25, alpha: 0.72) : UIColor.systemBackground.withAlphaComponent(0.92)
        secondsContainer.layer.borderColor = (isDark ? UIColor.white.withAlphaComponent(0.18) : UIColor.black.withAlphaComponent(0.10)).cgColor
        secondsLabel.textColor = textPrimary

        startButton.backgroundColor = accentColor
        startButton.layer.borderColor = (isDark ? UIColor.white.withAlphaComponent(0.14) : UIColor.black.withAlphaComponent(0.08)).cgColor
        startButton.setTitleColor(.white, for: .normal)
    }

    private func setupTraitObservation() {
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
                self.applyTheme()
                self.updateSoundButton()
            }
        }
    }
}
