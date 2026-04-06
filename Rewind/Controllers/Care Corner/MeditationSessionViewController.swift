//
//  MeditationSessionViewController.swift
//  Rewind
//
//  Created on 11/26/25.
//

import UIKit
import Combine

class MeditationSessionViewController: UIViewController {
    private let accentColor = UIColor(red: 0.30, green: 0.33, blue: 0.96, alpha: 1.0)
    private let minimumRewardSeconds = CareCornerViewModel.minimumRewardMeditationSeconds

    private let careCornerViewModel = CareCornerViewModel()

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
        label.text = "Mindfulness\nMeditation"
        label.font = UIFont.boldSystemFont(ofSize: 34)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private let progressContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private let progressBackgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    private let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red: 0.30, green: 0.33, blue: 0.96, alpha: 1.0)
        button.layer.cornerRadius = 40
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
        
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .bold)
        let playImage = UIImage(systemName: "play.fill", withConfiguration: config)
        button.setImage(playImage, for: .normal)
        button.tintColor = .white
        
        return button
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
    
    private let soundLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "  SOUND: CHIRPING BIRDS"
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        label.layer.cornerRadius = 20
        label.layer.borderWidth = 0.8
        label.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        label.clipsToBounds = true
        return label
    }()
    
    private let speakerIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        imageView.image = UIImage(systemName: "speaker.wave.2.fill", withConfiguration: config)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
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

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = UIImage(named: "illustrations/careCorner/meditationBgPattern")
        return iv
    }()

    private let gradientOverlay: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
        private var isPlaying = false

    private var hasStartedAutomatically = false
     private var timer: Timer?
     private var remainingSeconds: Int
     private var totalSeconds: Int
     private let soundName: String

    init(durationInSeconds: Int, soundName: String) {
        self.remainingSeconds = durationInSeconds
        self.totalSeconds = durationInSeconds
        self.soundName = soundName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.remainingSeconds = 300
        self.totalSeconds = 300
        self.soundName = "Chirping Birds"
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        updateTimerLabel()
        updateSoundLabel()
        applyTheme()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientOverlay.layer.sublayers?.first?.frame = gradientOverlay.bounds
        if progressBackgroundLayer.superlayer == nil {
            setupProgressLayers()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyTheme()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateProgress()

        if !hasStartedAutomatically {
            hasStartedAutomatically = true
            isPlaying = true

            let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .bold)
            let pauseImage = UIImage(systemName: "pause.fill", withConfiguration: config)
            playPauseButton.setImage(pauseImage, for: .normal)

            completeEarlyButton.isHidden = true

            startTimer()
            updateProgress()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }

    deinit {
        stopTimer()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.03, green: 0.05, blue: 0.16, alpha: 1.0)
        view.addSubview(backgroundImageView)
        view.addSubview(gradientOverlay)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            gradientOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            gradientOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.03, green: 0.05, blue: 0.16, alpha: 0.78).cgColor,
            UIColor(red: 0.10, green: 0.10, blue: 0.29, alpha: 0.68).cgColor,
            UIColor(red: 0.04, green: 0.05, blue: 0.17, alpha: 0.82).cgColor
        ]
        gradient.locations = [0.0, 0.45, 1.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientOverlay.layer.addSublayer(gradient)
         
         view.addSubview(backButton)
         view.addSubview(titleLabel)
         view.addSubview(progressContainer)
         progressContainer.addSubview(playPauseButton)
         view.addSubview(timerLabel)
         view.addSubview(soundLabel)
         soundLabel.addSubview(speakerIcon)
         view.addSubview(completeEarlyButton)
         completeEarlyButton.isHidden = true
         
         setupConstraints()
     }
    
     private func setupConstraints() {
         let safeArea = view.safeAreaLayoutGuide

         NSLayoutConstraint.activate([
             backButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 8),
             backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
             backButton.widthAnchor.constraint(equalToConstant: 44),
             backButton.heightAnchor.constraint(equalToConstant: 44),
             
             titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 24),
             titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

             progressContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             progressContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
             progressContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.50),
             progressContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 240),
             progressContainer.heightAnchor.constraint(equalTo: progressContainer.widthAnchor),
             
             playPauseButton.centerXAnchor.constraint(equalTo: progressContainer.centerXAnchor),
             playPauseButton.centerYAnchor.constraint(equalTo: progressContainer.centerYAnchor),
             playPauseButton.widthAnchor.constraint(equalToConstant: 80),
             playPauseButton.heightAnchor.constraint(equalToConstant: 80),
             
             timerLabel.topAnchor.constraint(equalTo: progressContainer.bottomAnchor, constant: 28),
             timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             
             soundLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 22),
             soundLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             soundLabel.heightAnchor.constraint(equalToConstant: 40),
             soundLabel.widthAnchor.constraint(equalToConstant: 240),
             
             speakerIcon.leadingAnchor.constraint(equalTo: soundLabel.leadingAnchor, constant: 16),
             speakerIcon.centerYAnchor.constraint(equalTo: soundLabel.centerYAnchor),
             speakerIcon.widthAnchor.constraint(equalToConstant: 20),
             speakerIcon.heightAnchor.constraint(equalToConstant: 20),
             
             completeEarlyButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -24),
             completeEarlyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
             completeEarlyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
             completeEarlyButton.heightAnchor.constraint(equalToConstant: 56)
         ])
     }
     
     private func setupProgressLayers() {
         let center = CGPoint(x: progressContainer.bounds.midX, y: progressContainer.bounds.midY)
         let radius = max(60.0, min(100.0, (progressContainer.bounds.width / 2) - 10))
         let startAngle = -CGFloat.pi / 2
         let endAngle = startAngle + (2 * CGFloat.pi)
         
         let circularPath = UIBezierPath(
             arcCenter: center,
             radius: radius,
             startAngle: startAngle,
             endAngle: endAngle,
             clockwise: true
         )
         
         progressBackgroundLayer.path = circularPath.cgPath
         progressBackgroundLayer.strokeColor = UIColor.white.withAlphaComponent(0.2).cgColor
         progressBackgroundLayer.lineWidth = 10
         progressBackgroundLayer.fillColor = UIColor.clear.cgColor
         progressBackgroundLayer.lineCap = .round

         progressLayer.path = circularPath.cgPath
         progressLayer.strokeColor = accentColor.cgColor
         progressLayer.lineWidth = 10
         progressLayer.fillColor = UIColor.clear.cgColor
         progressLayer.lineCap = .round
         progressLayer.strokeEnd = 0
         
         progressContainer.layer.addSublayer(progressBackgroundLayer)
         progressContainer.layer.addSublayer(progressLayer)
     }
     
     private func setupActions() {
         backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
         playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
         completeEarlyButton.addTarget(self, action: #selector(completeEarlyTapped), for: .touchUpInside)
     }
    
    private func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func updateTimer() {
        guard remainingSeconds > 0 else {
            meditationCompleted()
            return
        }
        
        remainingSeconds -= 1
        updateTimerLabel()
        updateProgress()
    }
    
    private func updateTimerLabel() {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateSoundLabel() {
        soundLabel.text = "  SOUND: \(soundName.uppercased())"
    }
    
    private func updateProgress() {
        let progress = 1.0 - (CGFloat(remainingSeconds) / CGFloat(totalSeconds))
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressLayer.strokeEnd = progress
        CATransaction.commit()
    }
    
    private func meditationCompleted() {
        stopTimer()

        completeSession(durationSeconds: totalSeconds)
    }

    private func completeSession(durationSeconds: Int) {
        let rewarded = durationSeconds >= minimumRewardSeconds
        let durationString = "\(max(1, durationSeconds / 60))M"

        Task {
            do {
                let pawsEarned = try await careCornerViewModel.recordMeditation(durationSeconds: durationSeconds, soundName: soundName)
                await MainActor.run {
                    let completedVC = ExerciseCompletedViewController(
                        duration: durationString,
                        pawsEarned: pawsEarned,
                        activityName: "Meditation",
                        rewarded: rewarded,
                        minimumRewardSeconds: minimumRewardSeconds
                    )
                    self.navigationController?.pushViewController(completedVC, animated: true)
                }
            } catch {
                await MainActor.run {
                    print("Error recording meditation: \(error)")
                    let fallbackPaws = rewarded ? max(0, (durationSeconds / 60) * 3) : 0
                    let completedVC = ExerciseCompletedViewController(
                        duration: durationString,
                        pawsEarned: fallbackPaws,
                        activityName: "Meditation",
                        rewarded: rewarded,
                        minimumRewardSeconds: minimumRewardSeconds
                    )
                    self.navigationController?.pushViewController(completedVC, animated: true)
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func backButtonTapped() {
        let alert = UIAlertController(title: "End Meditation?", message: "Are you sure you want to stop?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "End", style: .destructive) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    @objc private func playPauseTapped() {
        isPlaying.toggle()
        
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .bold)
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        let image = UIImage(systemName: imageName, withConfiguration: config)
        playPauseButton.setImage(image, for: .normal)
        
        if isPlaying {
            startTimer()
            completeEarlyButton.isHidden = true
            playPauseButton.backgroundColor = accentColor
            updateProgress()
        } else {
            stopTimer()
            completeEarlyButton.isHidden = false
            playPauseButton.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        }
        
        UIView.animate(withDuration: 0.1, animations: {
            self.playPauseButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.playPauseButton.transform = .identity
            }
        }
    }
    
    @objc private func completeEarlyTapped() {
        let elapsedSeconds = totalSeconds - remainingSeconds
        let minMinutes = max(1, minimumRewardSeconds / 60)
        let message = "You've meditated for \(formatElapsedTime()). Minimum for paws is \(minMinutes) minute\(minMinutes == 1 ? "" : "s")."
        let alert = UIAlertController(title: "Complete Early?", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Complete", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.stopTimer()
            self.completeSession(durationSeconds: max(0, elapsedSeconds))
        })
        present(alert, animated: true)
    }
    
    private func formatElapsedTime() -> String {
        let elapsed = totalSeconds - remainingSeconds
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%d min %d sec", minutes, seconds)
    }

    private func applyTheme() {
        let isDark = traitCollection.userInterfaceStyle != .light
        let textPrimary = isDark ? UIColor.white : UIColor.label
        let textSecondary = isDark ? UIColor.white.withAlphaComponent(0.9) : UIColor.secondaryLabel
        let controlBackground = isDark ? UIColor.white.withAlphaComponent(0.16) : UIColor.systemBackground.withAlphaComponent(0.9)
        let controlBorder = isDark ? UIColor.white.withAlphaComponent(0.22) : UIColor.black.withAlphaComponent(0.12)

        if let gradient = gradientOverlay.layer.sublayers?.first as? CAGradientLayer {
            gradient.colors = isDark
                ? [
                    UIColor(red: 0.03, green: 0.05, blue: 0.16, alpha: 0.78).cgColor,
                    UIColor(red: 0.10, green: 0.10, blue: 0.29, alpha: 0.68).cgColor,
                    UIColor(red: 0.04, green: 0.05, blue: 0.17, alpha: 0.82).cgColor
                ]
                : [
                    UIColor(red: 0.92, green: 0.95, blue: 1.00, alpha: 0.55).cgColor,
                    UIColor(red: 0.86, green: 0.91, blue: 1.00, alpha: 0.45).cgColor,
                    UIColor(red: 0.84, green: 0.89, blue: 1.00, alpha: 0.62).cgColor
                ]
        }

        backButton.tintColor = textPrimary
        backButton.backgroundColor = controlBackground
        backButton.layer.borderColor = controlBorder.cgColor

        titleLabel.textColor = textPrimary
        timerLabel.textColor = textPrimary
        soundLabel.textColor = textPrimary
        soundLabel.backgroundColor = controlBackground
        soundLabel.layer.borderColor = controlBorder.cgColor
        speakerIcon.tintColor = textPrimary

        completeEarlyButton.backgroundColor = controlBackground
        completeEarlyButton.layer.borderColor = controlBorder.cgColor
        completeEarlyButton.setTitleColor(textPrimary, for: .normal)

        if !isPlaying {
            playPauseButton.backgroundColor = controlBackground
            playPauseButton.tintColor = textSecondary
        } else {
            playPauseButton.backgroundColor = accentColor
            playPauseButton.tintColor = .white
        }
        progressBackgroundLayer.strokeColor = isDark ? UIColor.white.withAlphaComponent(0.2).cgColor : UIColor.black.withAlphaComponent(0.14).cgColor
    }
}
