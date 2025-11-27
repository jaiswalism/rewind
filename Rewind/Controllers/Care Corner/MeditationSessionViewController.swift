//
//  MeditationSessionViewController.swift
//  Rewind
//
//  Created on 11/26/25.
//

import UIKit

class MeditationSessionViewController: UIViewController {
    
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
        label.text = "Mindfulness\nMeditation"
        label.font = UIFont.boldSystemFont(ofSize: 36)
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
        button.backgroundColor = .clear
        
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
        label.backgroundColor = UIColor(red: 0.35, green: 0.38, blue: 0.75, alpha: 0.8)
        label.layer.cornerRadius = 20
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
        button.setTitleColor(UIColor(red: 0.35, green: 0.38, blue: 0.75, alpha: 1.0), for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 28
        return button
    }()

    // Background image that should cover the whole screen
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        // use asset catalog name
        iv.image = UIImage(named: "illustrations/careCorner/meditationBgPattern")
        return iv
    }()
    
    // MARK: - Properties
    // Note: gradient layer removed; using color asset + background image
     private var isPlaying = false
    // Ensure we only auto-start once when the screen first appears
    private var hasStartedAutomatically = false
     private var timer: Timer?
     private var remainingSeconds: Int
     private var totalSeconds: Int
     private let soundName: String
    
    // MARK: - Init
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        updateTimerLabel()
        updateSoundLabel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Only setup progress layers once (after layout so container bounds are valid)
        if progressBackgroundLayer.superlayer == nil {
            setupProgressLayers()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Initialize progress to show full circle
        updateProgress()
        
        // Auto-start the timer the first time the screen appears
        if !hasStartedAutomatically {
            hasStartedAutomatically = true
            isPlaying = true

            // Update play/pause button to show pause
            let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .bold)
            let pauseImage = UIImage(systemName: "pause.fill", withConfiguration: config)
            playPauseButton.setImage(pauseImage, for: .normal)

            // Hide the "Complete Early" button while playing
            completeEarlyButton.isHidden = true

            // Start the timer
            startTimer()
            updateProgress()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop timer when navigating away to avoid background execution
        stopTimer()
    }

    deinit {
        stopTimer()
    }

    // MARK: - Setup
    private func setupUI() {
        // Use the color asset 'blue-400' as the base background color (fallback provided)
        view.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-400") ?? UIColor(red: 0.4, green: 0.45, blue: 0.95, alpha: 1.0)
        
        // Add full-screen background image behind everything
        view.addSubview(backgroundImageView)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
         
         view.addSubview(backButton)
         view.addSubview(titleLabel)
         view.addSubview(progressContainer)
         progressContainer.addSubview(playPauseButton)
         view.addSubview(timerLabel)
         view.addSubview(soundLabel)
         soundLabel.addSubview(speakerIcon)
         view.addSubview(completeEarlyButton)
         
         setupConstraints()
     }
    
     private func setupConstraints() {
         NSLayoutConstraint.activate([
            // Background image constraints are set in setupUI (so image sits behind everything)
             // Back Button
             backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
             backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
             backButton.widthAnchor.constraint(equalToConstant: 44),
             backButton.heightAnchor.constraint(equalToConstant: 44),
             
             // Title
             titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 40),
             titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

             // Progress Container
             progressContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             progressContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
             progressContainer.widthAnchor.constraint(equalToConstant: 200),
             progressContainer.heightAnchor.constraint(equalToConstant: 200),
             
             // Play/Pause Button
             playPauseButton.centerXAnchor.constraint(equalTo: progressContainer.centerXAnchor),
             playPauseButton.centerYAnchor.constraint(equalTo: progressContainer.centerYAnchor),
             playPauseButton.widthAnchor.constraint(equalToConstant: 80),
             playPauseButton.heightAnchor.constraint(equalToConstant: 80),
             
             // Timer Label
             timerLabel.topAnchor.constraint(equalTo: progressContainer.bottomAnchor, constant: 40),
             timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             
             // Sound Label
             soundLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 30),
             soundLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             soundLabel.heightAnchor.constraint(equalToConstant: 40),
             soundLabel.widthAnchor.constraint(equalToConstant: 240),
             
             // Speaker Icon
             speakerIcon.leadingAnchor.constraint(equalTo: soundLabel.leadingAnchor, constant: 16),
             speakerIcon.centerYAnchor.constraint(equalTo: soundLabel.centerYAnchor),
             speakerIcon.widthAnchor.constraint(equalToConstant: 20),
             speakerIcon.heightAnchor.constraint(equalToConstant: 20),
             
             // Complete Early Button
             completeEarlyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
             completeEarlyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
             completeEarlyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
             completeEarlyButton.heightAnchor.constraint(equalToConstant: 56)
         ])
     }
     
     private func setupProgressLayers() {
         let center = CGPoint(x: progressContainer.bounds.midX, y: progressContainer.bounds.midY)
         let radius: CGFloat = 90
         let startAngle = -CGFloat.pi / 2
         let endAngle = startAngle + (2 * CGFloat.pi)
         
         let circularPath = UIBezierPath(
             arcCenter: center,
             radius: radius,
             startAngle: startAngle,
             endAngle: endAngle,
             clockwise: true
         )
         
         // Background layer
         progressBackgroundLayer.path = circularPath.cgPath
         progressBackgroundLayer.strokeColor = UIColor.white.withAlphaComponent(0.2).cgColor
         progressBackgroundLayer.lineWidth = 12
         progressBackgroundLayer.fillColor = UIColor.clear.cgColor
         progressBackgroundLayer.lineCap = .round
         
         // Progress layer
         progressLayer.path = circularPath.cgPath
         progressLayer.strokeColor = UIColor.white.withAlphaComponent(0.8).cgColor
         progressLayer.lineWidth = 12
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
    
    // MARK: - Timer
    private func startTimer() {
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
        
        // Calculate duration in minutes
        let completedMinutes = totalSeconds / 60
        let durationString = "\(completedMinutes)M"
        
        let completedVC = ExerciseCompletedViewController(duration: durationString, pawsEarned: completedMinutes * 20)
        navigationController?.pushViewController(completedVC, animated: true)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Actions
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
            // Ensure progress updates immediately
            updateProgress()
        } else {
            stopTimer()
            completeEarlyButton.isHidden = false
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
    
    @objc private func completeEarlyTapped() {
        let alert = UIAlertController(title: "Complete Early?", message: "You've meditated for \(formatElapsedTime()). Would you like to complete now?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Complete", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // Calculate elapsed time
            let elapsedSeconds = self.totalSeconds - self.remainingSeconds
            let elapsedMinutes = max(1, elapsedSeconds / 60) // At least 1 minute
            let durationString = "\(elapsedMinutes)M"
            
            let completedVC = ExerciseCompletedViewController(duration: durationString, pawsEarned: elapsedMinutes * 20)
            self.navigationController?.pushViewController(completedVC, animated: true)
        })
        present(alert, animated: true)
    }
    
    private func formatElapsedTime() -> String {
        let elapsed = totalSeconds - remainingSeconds
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%d min %d sec", minutes, seconds)
    }
}
