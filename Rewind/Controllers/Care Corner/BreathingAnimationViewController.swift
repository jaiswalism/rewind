//
//  BreathingAnimationViewController.swift
//  Rewind
//
//  Created on 11/26/25.
//

import UIKit

class BreathingAnimationViewController: UIViewController {
    
    // MARK: - UI Components
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
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
        view.backgroundColor = UIColor(red: 0.45, green: 0.48, blue: 0.85, alpha: 1.0)
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
        button.backgroundColor = UIColor(red: 0.35, green: 0.38, blue: 0.75, alpha: 1.0)
        button.layer.cornerRadius = 40
        
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .bold)
        let pauseImage = UIImage(systemName: "pause.fill", withConfiguration: config)
        button.setImage(pauseImage, for: .normal)
        button.tintColor = .white
        
        return button
    }()
    
    // MARK: - Properties
    private var gradientLayer: CAGradientLayer?
    private var isPlaying = true
    private var timer: Timer?
    private var remainingSeconds: Int
    private var breathingTimer: Timer?
    private var isBreathingIn = true
    
    private let breathInDuration: TimeInterval = 4.0
    private let breathOutDuration: TimeInterval = 4.0
    private let holdDuration: TimeInterval = 1.0
    
    // MARK: - Init
    init(durationInSeconds: Int) {
        self.remainingSeconds = durationInSeconds
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.remainingSeconds = 300
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
        
        // Set corner radius based on actual size
        outerCircle.layer.cornerRadius = outerCircle.bounds.width / 2
        middleCircle.layer.cornerRadius = middleCircle.bounds.width / 2
        innerCircle.layer.cornerRadius = innerCircle.bounds.width / 2
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startBreathingAnimation()
        startTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAllAnimations()
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
        view.addSubview(breathingBlobContainer)
        breathingBlobContainer.addSubview(outerCircle)
        breathingBlobContainer.addSubview(middleCircle)
        breathingBlobContainer.addSubview(innerCircle)
        breathingBlobContainer.addSubview(breathingLabel)
        view.addSubview(timerLabel)
        view.addSubview(playPauseButton)
        
        updateTimerLabel()
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Back Button
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Breathing Blob Container
            breathingBlobContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            breathingBlobContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            breathingBlobContainer.widthAnchor.constraint(equalToConstant: 500),
            breathingBlobContainer.heightAnchor.constraint(equalToConstant: 500),
            
            // Outer Circle
            outerCircle.centerXAnchor.constraint(equalTo: breathingBlobContainer.centerXAnchor),
            outerCircle.centerYAnchor.constraint(equalTo: breathingBlobContainer.centerYAnchor),
            outerCircle.widthAnchor.constraint(equalToConstant: 500),
            outerCircle.heightAnchor.constraint(equalToConstant: 500),
            
            // Middle Circle
            middleCircle.centerXAnchor.constraint(equalTo: breathingBlobContainer.centerXAnchor),
            middleCircle.centerYAnchor.constraint(equalTo: breathingBlobContainer.centerYAnchor),
            middleCircle.widthAnchor.constraint(equalToConstant: 380),
            middleCircle.heightAnchor.constraint(equalToConstant: 380),
            
            // Inner Circle
            innerCircle.centerXAnchor.constraint(equalTo: breathingBlobContainer.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: breathingBlobContainer.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 260),
            innerCircle.heightAnchor.constraint(equalToConstant: 260),
            
            // Breathing Label
            breathingLabel.centerXAnchor.constraint(equalTo: breathingBlobContainer.centerXAnchor),
            breathingLabel.centerYAnchor.constraint(equalTo: breathingBlobContainer.centerYAnchor),
            
            // Timer Label
            timerLabel.topAnchor.constraint(equalTo: breathingBlobContainer.bottomAnchor, constant: 80),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Play/Pause Button
            playPauseButton.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 40),
            playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 80),
            playPauseButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
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
        
        let alert = UIAlertController(title: "Great Job!", message: "You've completed your breathing exercise.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
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
    
    @objc private func playPauseTapped() {
        isPlaying.toggle()
        
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .bold)
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        let image = UIImage(systemName: imageName, withConfiguration: config)
        playPauseButton.setImage(image, for: .normal)
        
        if isPlaying {
            startTimer()
            performBreathingCycle()
            
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
}
