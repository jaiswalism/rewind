//
//  PetTalkingViewController.swift
//  Rewind
//
//  Created on 12/26/25.
//

import UIKit
import Speech
import AVFoundation

class PetTalkingViewController: UIViewController {
    
    // MARK: - UI Components
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let image = UIImage(systemName: "chevron.left", withConfiguration: symbolConfig)
        
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.image = image
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
            config.baseForegroundColor = UIColor(named: "colors/Primary/Light") ?? .white
            button.configuration = config
        } else {
            button.setImage(image, for: .normal)
            button.tintColor = UIColor(named: "colors/Primary/Light") ?? .white
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        }
        
        button.backgroundColor = UIColor.clear
        
        // Make sure the button is interactive
        button.isUserInteractionEnabled = true
        button.isEnabled = true
        
        return button
    }()
    
    private let animatedBlobContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let outerBlob: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        return view
    }()
    
    private let middleBlob: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        return view
    }()
    
    private let innerBlob: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(named: "colors/Primary/Light")?.withAlphaComponent(0.8) ?? UIColor.white.withAlphaComponent(0.8)
        return view
    }()
    
    private let centerDot: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(named: "colors/Primary/Dark") ?? UIColor.blue
        return view
    }()
    
    private let transcriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Tap to start talking..."
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = UIColor(named: "colors/Primary/Light") ?? .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.alpha = 0.8
        return label
    }()
    
    private let micButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        let image = UIImage(systemName: "mic.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = UIColor(named: "colors/Primary/Light") ?? .white
        button.backgroundColor = UIColor(named: "colors/Primary/Dark")?.withAlphaComponent(0.3) ?? UIColor.blue.withAlphaComponent(0.3)
        button.layer.cornerRadius = 30
        return button
    }()
    
    // MARK: - Properties
    private var gradientLayer: CAGradientLayer?
    private var animationTimer: Timer?
    private var isAnimating = false
    
    // Speech Recognition Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isRecording = false
    private var audioLevelTimer: Timer?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("PetTalkingViewController loaded") // Debug log
        setupUI()
        setupActions()
        requestSpeechPermission()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("PetTalkingViewController appeared") // Debug log
        print("Back button frame: \(backButton.frame)")
        print("Back button superview: \(backButton.superview != nil)")
        print("Back button isUserInteractionEnabled: \(backButton.isUserInteractionEnabled)")
        print("Back button isEnabled: \(backButton.isEnabled)")
        print("Navigation controller: \(navigationController != nil)")
        startBlobAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopBlobAnimation()
        stopRecording()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
        
        // Set corner radius for blob elements
        outerBlob.layer.cornerRadius = outerBlob.bounds.width / 2
        middleBlob.layer.cornerRadius = middleBlob.bounds.width / 2
        innerBlob.layer.cornerRadius = innerBlob.bounds.width / 2
        centerDot.layer.cornerRadius = centerDot.bounds.width / 2
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Set background color matching app theme
        view.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-400") ?? UIColor(red: 0.38, green: 0.38, blue: 1.0, alpha: 1.0)
        
        // Add gradient background similar to other screens
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            (UIColor(named: "colors/Blue&Shades/blue-400") ?? UIColor(red: 0.38, green: 0.38, blue: 1.0, alpha: 1.0)).cgColor,
            (UIColor(named: "colors/Blue&Shades/blue-300") ?? UIColor(red: 0.48, green: 0.48, blue: 1.0, alpha: 1.0)).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        view.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
        
        // Hide navigation bar to match app style
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Add views in correct order (back button last to be on top)
        view.addSubview(animatedBlobContainer)
        view.addSubview(transcriptionLabel)
        view.addSubview(micButton)
        view.addSubview(backButton) // Add back button last so it's on top
        
        // Add blob elements to container
        animatedBlobContainer.addSubview(outerBlob)
        animatedBlobContainer.addSubview(middleBlob)
        animatedBlobContainer.addSubview(innerBlob)
        animatedBlobContainer.addSubview(centerDot)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Back Button - larger touch area
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 50),
            backButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Animated Blob Container - moved up
            animatedBlobContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animatedBlobContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            animatedBlobContainer.widthAnchor.constraint(equalToConstant: 300),
            animatedBlobContainer.heightAnchor.constraint(equalToConstant: 300),
            
            // Outer Blob
            outerBlob.centerXAnchor.constraint(equalTo: animatedBlobContainer.centerXAnchor),
            outerBlob.centerYAnchor.constraint(equalTo: animatedBlobContainer.centerYAnchor),
            outerBlob.widthAnchor.constraint(equalToConstant: 300),
            outerBlob.heightAnchor.constraint(equalToConstant: 300),
            
            // Middle Blob
            middleBlob.centerXAnchor.constraint(equalTo: animatedBlobContainer.centerXAnchor),
            middleBlob.centerYAnchor.constraint(equalTo: animatedBlobContainer.centerYAnchor),
            middleBlob.widthAnchor.constraint(equalToConstant: 220),
            middleBlob.heightAnchor.constraint(equalToConstant: 220),
            
            // Inner Blob
            innerBlob.centerXAnchor.constraint(equalTo: animatedBlobContainer.centerXAnchor),
            innerBlob.centerYAnchor.constraint(equalTo: animatedBlobContainer.centerYAnchor),
            innerBlob.widthAnchor.constraint(equalToConstant: 150),
            innerBlob.heightAnchor.constraint(equalToConstant: 150),
            
            // Center Dot
            centerDot.centerXAnchor.constraint(equalTo: animatedBlobContainer.centerXAnchor),
            centerDot.centerYAnchor.constraint(equalTo: animatedBlobContainer.centerYAnchor),
            centerDot.widthAnchor.constraint(equalToConstant: 40),
            centerDot.heightAnchor.constraint(equalToConstant: 40),
            
            // Transcription Label
            transcriptionLabel.topAnchor.constraint(equalTo: animatedBlobContainer.bottomAnchor, constant: 40),
            transcriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            transcriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Mic Button
            micButton.topAnchor.constraint(equalTo: transcriptionLabel.bottomAnchor, constant: 40),
            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 60),
            micButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        micButton.addTarget(self, action: #selector(micButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Blob Animation
    private func startBlobAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        
        // Start continuous pulsing animation
        animateBlobPulse()
        
        // Start morphing animation with timer
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.animateBlobMorph()
        }
    }
    
    private func stopBlobAnimation() {
        isAnimating = false
        animationTimer?.invalidate()
        animationTimer = nil
        
        // Stop all animations
        outerBlob.layer.removeAllAnimations()
        middleBlob.layer.removeAllAnimations()
        innerBlob.layer.removeAllAnimations()
        centerDot.layer.removeAllAnimations()
    }
    
    private func animateBlobPulse() {
        guard isAnimating else { return }
        
        // Outer blob - slow pulse
        UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.outerBlob.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.outerBlob.alpha = 0.3
        })
        
        // Middle blob - medium pulse
        UIView.animate(withDuration: 1.5, delay: 0.2, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.middleBlob.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.middleBlob.alpha = 0.5
        })
        
        // Inner blob - fast pulse
        UIView.animate(withDuration: 1.0, delay: 0.4, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.innerBlob.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.innerBlob.alpha = 0.9
        })
        
        // Center dot - rapid pulse
        UIView.animate(withDuration: 0.8, delay: 0.6, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.centerDot.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        })
    }
    
    private func animateBlobMorph() {
        guard isAnimating else { return }
        
        // Random morphing effects
        let randomScale = Double.random(in: 0.95...1.05)
        let randomRotation = Double.random(in: -0.1...0.1)
        let randomOpacity = Double.random(in: 0.7...1.0)
        
        // Apply subtle random transformations
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            // Slight morphing for organic feel
            self.outerBlob.transform = self.outerBlob.transform.scaledBy(x: randomScale, y: randomScale).rotated(by: randomRotation)
            
            let middleScale = Double.random(in: 0.98...1.02)
            self.middleBlob.transform = self.middleBlob.transform.scaledBy(x: middleScale, y: middleScale)
            
            // Subtle opacity changes
            self.innerBlob.alpha = randomOpacity
        })
    }
    
    // MARK: - Speech Recognition
    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("Speech recognition denied")
                    self?.transcriptionLabel.text = "Speech recognition denied"
                case .restricted:
                    print("Speech recognition restricted")
                    self?.transcriptionLabel.text = "Speech recognition restricted"
                case .notDetermined:
                    print("Speech recognition not determined")
                    self?.transcriptionLabel.text = "Speech recognition not available"
                @unknown default:
                    print("Speech recognition unknown status")
                }
            }
        }
    }
    
    private func startRecording() {
        guard !isRecording else { return }
        
        // Cancel previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            recognitionRequest.append(buffer)
            
            // Calculate audio level for blob animation
            self?.processAudioLevel(buffer: buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start failed: \(error)")
            return
        }
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    let transcription = result.bestTranscription.formattedString
                    self?.transcriptionLabel.text = transcription
                    
                    // Animate blob based on speech
                    self?.animateBlobForSpeech(intensity: min(transcription.count / 10, 5))
                }
                
                if error != nil || result?.isFinal == true {
                    self?.stopRecording()
                }
            }
        }
        
        isRecording = true
        updateMicButton()
        transcriptionLabel.text = "Listening..."
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        
        isRecording = false
        updateMicButton()
        
        if transcriptionLabel.text == "Listening..." {
            transcriptionLabel.text = "Tap to start talking..."
        }
    }
    
    private func processAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0
        
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }
        
        let averageLevel = sum / Float(frameLength)
        let normalizedLevel = min(averageLevel * 10, 1.0) // Normalize to 0-1
        
        DispatchQueue.main.async { [weak self] in
            self?.animateBlobForAudio(level: normalizedLevel)
        }
    }
    
    private func updateMicButton() {
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        let imageName = isRecording ? "mic.slash.fill" : "mic.fill"
        let image = UIImage(systemName: imageName, withConfiguration: config)
        micButton.setImage(image, for: .normal)
        
        UIView.animate(withDuration: 0.2) {
            self.micButton.backgroundColor = self.isRecording ? 
                UIColor.red.withAlphaComponent(0.3) : 
                UIColor(named: "colors/Primary/Dark")?.withAlphaComponent(0.3) ?? UIColor.blue.withAlphaComponent(0.3)
        }
    }
    
    private func animateBlobForAudio(level: Float) {
        guard isRecording else { return }
        
        let intensity = CGFloat(level)
        let scale = 1.0 + (intensity * 0.5) // Scale based on audio level
        
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: {
            self.outerBlob.transform = CGAffineTransform(scaleX: scale * 1.1, y: scale * 1.1)
            self.middleBlob.transform = CGAffineTransform(scaleX: scale * 1.2, y: scale * 1.2)
            self.innerBlob.transform = CGAffineTransform(scaleX: scale * 1.3, y: scale * 1.3)
            self.centerDot.transform = CGAffineTransform(scaleX: scale * 1.4, y: scale * 1.4)
            
            // Adjust opacity based on audio level
            self.outerBlob.alpha = 0.1 + (intensity * 0.3)
            self.middleBlob.alpha = 0.2 + (intensity * 0.4)
            self.innerBlob.alpha = 0.8 + (intensity * 0.2)
        })
    }
    
    private func animateBlobForSpeech(intensity: Int) {
        let scale = 1.0 + (CGFloat(intensity) * 0.1)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.outerBlob.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.middleBlob.transform = CGAffineTransform(scaleX: scale * 1.1, y: scale * 1.1)
            self.innerBlob.transform = CGAffineTransform(scaleX: scale * 1.2, y: scale * 1.2)
        })
    }
    
    // MARK: - Actions
    @objc private func micButtonTapped() {
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Animate button press
        UIView.animate(withDuration: 0.1, animations: {
            self.micButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.micButton.transform = .identity
            }
        }
        
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        print("🔙 Back button tapped - starting navigation") // Debug log
        
        // Stop recording if active
        if isRecording {
            print("🔙 Stopping recording before navigation")
            stopRecording()
        }
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Animate button press
        UIView.animate(withDuration: 0.1, animations: {
            self.backButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.backButton.transform = .identity
            }
        }
        
        // Navigate back
        if let navController = navigationController {
            print("🔙 Using navigation controller to pop")
            navController.popViewController(animated: true)
        } else {
            print("🔙 No navigation controller, using dismiss")
            dismiss(animated: true)
        }
    }
}
