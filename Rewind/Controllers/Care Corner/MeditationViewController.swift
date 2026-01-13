//
//  MeditationViewController.swift
//  Rewind
//
//  Created on 11/26/25.
//

import UIKit

class MeditationViewController: UIViewController {
    
    // MARK: - UI Components
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "How long do you want to\nmeditate?"
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let minutesContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0.35, green: 0.38, blue: 0.75, alpha: 1.0)
        view.layer.cornerRadius = 40
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
        view.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        view.layer.cornerRadius = 40
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
        
        // Add speaker icon
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let speakerImage = UIImage(systemName: "speaker.wave.2.fill", withConfiguration: config)
        
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.filled()
            configuration.baseBackgroundColor = UIColor(red: 0.35, green: 0.38, blue: 0.75, alpha: 0.8)
            configuration.baseForegroundColor = .white
            configuration.title = "  SOUND: CHIRPING BIRDS"
            configuration.image = speakerImage
            configuration.imagePadding = 8
            configuration.imagePlacement = .leading
            // configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
            
            // Re-apply font locally since Configuration ignores global titleLabel font sometimes w/o AttributedString container
            var container = AttributeContainer()
            container.font = UIFont.boldSystemFont(ofSize: 13)
            configuration.attributedTitle = AttributedString("  SOUND: CHIRPING BIRDS", attributes: container)
            
            button.configuration = configuration
        } else {
            button.setTitle("  SOUND: CHIRPING BIRDS", for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = UIColor(red: 0.35, green: 0.38, blue: 0.75, alpha: 0.8)
            button.setImage(speakerImage, for: .normal)
            button.tintColor = .white
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        }
        
        button.layer.cornerRadius = 20
        // button.contentHorizontalAlignment = .center // Not needed with configuration typically, but handled
        
        return button
    }()
    
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Start Exercise", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitleColor(UIColor(red: 0.35, green: 0.38, blue: 0.75, alpha: 1.0), for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 28
        
        return button
    }()
    
    // MARK: - Properties
    private var gradientLayer: CAGradientLayer?
    private var selectedMinutes: Int = 25
    private var selectedSeconds: Int = 0
    private var selectedSound: String = "Chirping Birds"
    
    private let soundOptions = ["Chirping Birds", "Ocean Waves", "Rain", "Forest", "White Noise", "Silence"]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupGestures()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.4, green: 0.45, blue: 0.95, alpha: 1.0)
        
        // Add gradient background
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor(red: 0.35, green: 0.4, blue: 0.9, alpha: 1.0).cgColor,
            UIColor(red: 0.45, green: 0.5, blue: 1.0, alpha: 1.0).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        view.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
        
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(minutesContainer)
        view.addSubview(secondsContainer)
        minutesContainer.addSubview(minutesLabel)
        secondsContainer.addSubview(secondsLabel)
        view.addSubview(soundButton)
        view.addSubview(startButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Back Button
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 120),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Minutes Container
            minutesContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 60),
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
            
            // Sound Button
            soundButton.topAnchor.constraint(equalTo: minutesContainer.bottomAnchor, constant: 40),
            soundButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            soundButton.heightAnchor.constraint(equalToConstant: 40),
            soundButton.widthAnchor.constraint(equalToConstant: 240),
            
            // Start Button
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            startButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        startButton.addTarget(self, action: #selector(startExerciseTapped), for: .touchUpInside)
        soundButton.addTarget(self, action: #selector(soundButtonTapped), for: .touchUpInside)
    }
    
    private func setupGestures() {
        // Add swipe gestures for minutes
        let minutesSwipeUp = UISwipeGestureRecognizer(target: self, action: #selector(minutesSwipedUp))
        minutesSwipeUp.direction = .up
        minutesContainer.addGestureRecognizer(minutesSwipeUp)
        
        let minutesSwipeDown = UISwipeGestureRecognizer(target: self, action: #selector(minutesSwipedDown))
        minutesSwipeDown.direction = .down
        minutesContainer.addGestureRecognizer(minutesSwipeDown)
        
        // Add swipe gestures for seconds
        let secondsSwipeUp = UISwipeGestureRecognizer(target: self, action: #selector(secondsSwipedUp))
        secondsSwipeUp.direction = .up
        secondsContainer.addGestureRecognizer(secondsSwipeUp)
        
        let secondsSwipeDown = UISwipeGestureRecognizer(target: self, action: #selector(secondsSwipedDown))
        secondsSwipeDown.direction = .down
        secondsContainer.addGestureRecognizer(secondsSwipeDown)
        
        // Add tap gestures for direct interaction
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
        let sessionVC = MeditationSessionViewController(durationInSeconds: totalSeconds, soundName: selectedSound)
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
        // Cycle through common meditation values: 5, 10, 15, 20, 25, 30
        let commonValues = [5, 10, 15, 20, 25, 30]
        if let currentIndex = commonValues.firstIndex(of: selectedMinutes) {
            selectedMinutes = commonValues[(currentIndex + 1) % commonValues.count]
        } else {
            selectedMinutes = 25
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
    
    private func updateSoundButton() {
        let title = "  SOUND: \(selectedSound.uppercased())"
        if #available(iOS 15.0, *) {
            if var config = soundButton.configuration {
                var container = AttributeContainer()
                container.font = UIFont.boldSystemFont(ofSize: 13)
                config.attributedTitle = AttributedString(title, attributes: container)
                soundButton.configuration = config
            } else {
                soundButton.setTitle(title, for: .normal)
            }
        } else {
            soundButton.setTitle(title, for: .normal)
        }
    }
}
