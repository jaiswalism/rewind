//
//  BreathingAnimationViewController.swift
//  Rewind
//
//  Created on 11/26/25.
//

import UIKit
import Combine

class BreathingAnimationViewController: UIViewController {
    private let accentColor = UIColor(red: 0.30, green: 0.33, blue: 0.96, alpha: 1.0)
    private let minimumRewardSeconds = CareCornerViewModel.minimumRewardBreathingSeconds
    
    // MARK: - ViewModels
    private let careCornerViewModel = CareCornerViewModel()
    
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
    
    private let breathingBlobContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let outerCircle: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        return view
    }()
    
    private let middleCircle: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        return view
    }()
    
    private let innerCircle: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0.30, green: 0.33, blue: 0.96, alpha: 0.95)
        return view
    }()
    
    private let breathingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Breathe In..."
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "05:00"
        label.font = UIFont.boldSystemFont(ofSize: 48)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red: 0.30, green: 0.33, blue: 0.96, alpha: 1.0)
        button.layer.cornerRadius = 40
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
        
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .bold)
        let pauseImage = UIImage(systemName: "pause.fill", withConfiguration: config)
        button.setImage(pauseImage, for: .normal)
        button.tintColor = .white
        
        return button
    }()

    private let completeEarlyButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Complete Early", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        button.layer.borderWidth = 0.8
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        button.layer.cornerRadius = 28
        return button
    }()
    
    // MARK: - Properties
    private var gradientLayer: CAGradientLayer?
    private var isPlaying = true
    private var timer: Timer?
    private var remainingSeconds: Int
    private var totalSeconds: Int?
    private var breathingTimer: Timer?
    private var isBreathingIn = true
    
    private let breathInDuration: TimeInterval = 4.0
    private let breathOutDuration: TimeInterval = 4.0
    private let holdDuration: TimeInterval = 1.0
    
    // MARK: - Init
    init(durationInSeconds: Int) {
        self.remainingSeconds = durationInSeconds
        self.totalSeconds = durationInSeconds
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.remainingSeconds = 300
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hidesBottomBarWhenPushed = true
        setupUI()
        setupActions()
        applyTheme()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
        
        // Set corner radius based on actual size
        outerCircle.layer.cornerRadius = outerCircle.bounds.width / 2
        middleCircle.layer.cornerRadius = middleCircle.bounds.width / 2
        innerCircle.layer.cornerRadius = innerCircle.bounds.width / 2
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyTheme()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startBreathingAnimation()
        startTimer()
        completeEarlyButton.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAllAnimations()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add gradient background
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor(red: 0.03, green: 0.05, blue: 0.16, alpha: 1.0).cgColor,
            UIColor(red: 0.08, green: 0.09, blue: 0.28, alpha: 1.0).cgColor,
            UIColor(red: 0.13, green: 0.12, blue: 0.36, alpha: 1.0).cgColor
        ]
        gradient.locations = [0.0, 0.5, 1.0]
        view.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
        
        view.addSubview(backButton)
        view.addSubview(breathingBlobContainer)
        breathingBlobContainer.addSubview(outerCircle)
        breathingBlobContainer.addSubview(middleCircle)
        breathingBlobContainer.addSubview(innerCircle)
        breathingBlobContainer.addSubview(breathingLabel)
        view.addSubview(timerLabel)
        view.addSubview(playPauseButton)
        view.addSubview(completeEarlyButton)
        
        updateTimerLabel()
        setupConstraints()
    }
    
    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            breathingBlobContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            breathingBlobContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            breathingBlobContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.84),
            breathingBlobContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 360),
            breathingBlobContainer.heightAnchor.constraint(equalTo: breathingBlobContainer.widthAnchor),

            outerCircle.centerXAnchor.constraint(equalTo: breathingBlobContainer.centerXAnchor),
            outerCircle.centerYAnchor.constraint(equalTo: breathingBlobContainer.centerYAnchor),
            outerCircle.widthAnchor.constraint(equalTo: breathingBlobContainer.widthAnchor),
            outerCircle.heightAnchor.constraint(equalTo: breathingBlobContainer.heightAnchor),

            middleCircle.centerXAnchor.constraint(equalTo: breathingBlobContainer.centerXAnchor),
            middleCircle.centerYAnchor.constraint(equalTo: breathingBlobContainer.centerYAnchor),
            middleCircle.widthAnchor.constraint(equalTo: breathingBlobContainer.widthAnchor, multiplier: 0.76),
            middleCircle.heightAnchor.constraint(equalTo: breathingBlobContainer.heightAnchor, multiplier: 0.76),

            innerCircle.centerXAnchor.constraint(equalTo: breathingBlobContainer.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: breathingBlobContainer.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalTo: breathingBlobContainer.widthAnchor, multiplier: 0.52),
            innerCircle.heightAnchor.constraint(equalTo: breathingBlobContainer.heightAnchor, multiplier: 0.52),

            breathingLabel.centerXAnchor.constraint(equalTo: breathingBlobContainer.centerXAnchor),
            breathingLabel.centerYAnchor.constraint(equalTo: breathingBlobContainer.centerYAnchor),

            timerLabel.topAnchor.constraint(equalTo: breathingBlobContainer.bottomAnchor, constant: 44),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            playPauseButton.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 22),
            playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 80),
            playPauseButton.heightAnchor.constraint(equalToConstant: 80),

            completeEarlyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            completeEarlyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            completeEarlyButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -24),
            completeEarlyButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        completeEarlyButton.addTarget(self, action: #selector(completeEarlyTapped), for: .touchUpInside)
    }
    
    // MARK: - Breathing Animation
    private func startBreathingAnimation() {
        breathingTimer?.invalidate()
        performBreathingCycle()
    }
    
    private func performBreathingCycle() {
        guard isPlaying else { return }
        
        if isBreathingIn {
            breatheIn()
        } else {
            breatheOut()
        }
    }
    
    private func breatheIn() {
        isBreathingIn = true
        breathingLabel.text = "Breathe In..."
        
        UIView.animate(withDuration: breathInDuration, delay: 0, options: [.curveEaseInOut], animations: {
            self.outerCircle.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.middleCircle.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.innerCircle.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            self.outerCircle.alpha = 0.8
            self.middleCircle.alpha = 0.9
        }) { _ in
            self.breathingTimer = Timer.scheduledTimer(withTimeInterval: self.holdDuration, repeats: false) { _ in
                self.isBreathingIn = false
                self.performBreathingCycle()
            }
        }
    }
    
    private func breatheOut() {
        isBreathingIn = false
        breathingLabel.text = "Breathe Out..."
        
        UIView.animate(withDuration: breathOutDuration, delay: 0, options: [.curveEaseInOut], animations: {
            self.outerCircle.transform = .identity
            self.middleCircle.transform = .identity
            self.innerCircle.transform = .identity
            self.outerCircle.alpha = 1.0
            self.middleCircle.alpha = 1.0
        }) { _ in
            self.breathingTimer = Timer.scheduledTimer(withTimeInterval: self.holdDuration, repeats: false) { _ in
                self.isBreathingIn = true
                self.performBreathingCycle()
            }
        }
    }
    
    private func stopAllAnimations() {
        timer?.invalidate()
        breathingTimer?.invalidate()
        outerCircle.layer.removeAllAnimations()
        middleCircle.layer.removeAllAnimations()
        innerCircle.layer.removeAllAnimations()
    }
    
    // MARK: - Timer
    private func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func updateTimer() {
        guard remainingSeconds > 0 else {
            exerciseCompleted()
            return
        }
        
        remainingSeconds -= 1
        updateTimerLabel()
    }
    
    private func updateTimerLabel() {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func exerciseCompleted() {
        stopAllAnimations()

        let duration = self.totalSeconds ?? 300
        completeSession(durationSeconds: duration)
    }

    private func completeSession(durationSeconds: Int) {
        let rewarded = durationSeconds >= minimumRewardSeconds
        let durationMinutes = max(1, durationSeconds / 60)
        let durationString = "\(durationMinutes)M"
        
        Task {
            do {
                let pawsEarned = try await careCornerViewModel.recordBreathing(durationSeconds: durationSeconds)
                await MainActor.run {
                    let completedVC = ExerciseCompletedViewController(
                        duration: durationString,
                        pawsEarned: pawsEarned,
                        activityName: "Breathing",
                        rewarded: rewarded,
                        minimumRewardSeconds: minimumRewardSeconds
                    )
                    self.navigationController?.pushViewController(completedVC, animated: true)
                }
            } catch {
                await MainActor.run {
                    print("Error recording breathing: \(error)")
                    let fallbackPaws = rewarded ? max(0, (durationSeconds / 60) * 2) : 0
                    let completedVC = ExerciseCompletedViewController(
                        duration: durationString,
                        pawsEarned: fallbackPaws,
                        activityName: "Breathing",
                        rewarded: rewarded,
                        minimumRewardSeconds: minimumRewardSeconds
                    )
                    self.navigationController?.pushViewController(completedVC, animated: true)
                }
            }
        }
    }

    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        let alert = UIAlertController(title: "End Exercise?", message: "Are you sure you want to stop?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "End", style: .destructive) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    @objc private func completeEarlyTapped() {
        let elapsed = (totalSeconds ?? remainingSeconds) - remainingSeconds
        let minMinutes = max(1, minimumRewardSeconds / 60)
        let message = "You've completed \(formatElapsedTime(elapsed)). Minimum for paws is \(minMinutes) minute\(minMinutes == 1 ? "" : "s")."
        let alert = UIAlertController(title: "Complete Early?", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Complete", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.stopAllAnimations()
            self.completeSession(durationSeconds: max(0, elapsed))
        })
        present(alert, animated: true)
    }
    
    @objc private func playPauseTapped() {
        isPlaying.toggle()
        
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .bold)
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        let image = UIImage(systemName: imageName, withConfiguration: config)
        playPauseButton.setImage(image, for: .normal)
        
        if isPlaying {
            startTimer()
            performBreathingCycle()
            playPauseButton.backgroundColor = accentColor
            completeEarlyButton.isHidden = true
            
            // Show circles with animation
            UIView.animate(withDuration: 0.3) {
                self.outerCircle.alpha = 1.0
                self.middleCircle.alpha = 1.0
                self.innerCircle.alpha = 1.0
            }
        } else {
            timer?.invalidate()
            breathingTimer?.invalidate()
            breathingLabel.text = "Paused"
            playPauseButton.backgroundColor = UIColor.white.withAlphaComponent(0.18)
            completeEarlyButton.isHidden = false
            
            // Hide circles with animation
            UIView.animate(withDuration: 0.3) {
                self.outerCircle.alpha = 0.0
                self.middleCircle.alpha = 0.0
                self.innerCircle.alpha = 0.0
            }
        }
        
        // Animate button press
        UIView.animate(withDuration: 0.1, animations: {
            self.playPauseButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.playPauseButton.transform = .identity
            }
        }
    }

    private func formatElapsedTime(_ elapsed: Int) -> String {
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%d min %d sec", minutes, seconds)
    }

    private func applyTheme() {
        let isDark = traitCollection.userInterfaceStyle != .light
        let primaryText = isDark ? UIColor.white : UIColor.label
        let secondaryText = isDark ? UIColor.white.withAlphaComponent(0.9) : UIColor.secondaryLabel
        let controlBackground = isDark ? UIColor.white.withAlphaComponent(0.16) : UIColor.systemBackground.withAlphaComponent(0.9)
        let controlBorder = isDark ? UIColor.white.withAlphaComponent(0.22) : UIColor.black.withAlphaComponent(0.12)

        if let gradientLayer {
            gradientLayer.colors = isDark
                ? [
                    UIColor(red: 0.03, green: 0.05, blue: 0.16, alpha: 1.0).cgColor,
                    UIColor(red: 0.08, green: 0.09, blue: 0.28, alpha: 1.0).cgColor,
                    UIColor(red: 0.13, green: 0.12, blue: 0.36, alpha: 1.0).cgColor
                ]
                : [
                    UIColor(red: 0.93, green: 0.95, blue: 1.00, alpha: 1.0).cgColor,
                    UIColor(red: 0.87, green: 0.91, blue: 1.00, alpha: 1.0).cgColor,
                    UIColor(red: 0.80, green: 0.86, blue: 1.00, alpha: 1.0).cgColor
                ]
        }

        backButton.tintColor = primaryText
        backButton.backgroundColor = controlBackground
        backButton.layer.borderColor = controlBorder.cgColor

        breathingLabel.textColor = primaryText
        timerLabel.textColor = primaryText

        completeEarlyButton.backgroundColor = controlBackground
        completeEarlyButton.layer.borderColor = controlBorder.cgColor
        completeEarlyButton.setTitleColor(primaryText, for: .normal)

        let ringBase = isDark ? UIColor.white.withAlphaComponent(0.15) : UIColor(red: 0.25, green: 0.30, blue: 0.72, alpha: 0.12)
        let ringMid = isDark ? UIColor.white.withAlphaComponent(0.25) : UIColor(red: 0.25, green: 0.30, blue: 0.72, alpha: 0.18)
        outerCircle.backgroundColor = ringBase
        middleCircle.backgroundColor = ringMid
        innerCircle.backgroundColor = accentColor.withAlphaComponent(isDark ? 0.95 : 0.88)
        breathingLabel.textColor = isPlaying ? primaryText : secondaryText
    }
}
