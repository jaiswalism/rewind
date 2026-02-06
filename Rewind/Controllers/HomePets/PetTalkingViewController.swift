//
//  PetTalkingViewController.swift
//  Rewind
//
//  Created on 12/26/25.
//

import UIKit
import Speech
import AVFoundation
import SceneKit

class PetTalkingViewController: UIViewController {
    
    // MARK: - Init
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        hidesBottomBarWhenPushed = true
    }
    
    // MARK: - Constants
    private let petBaseScale: Float = 0.13
    
    // MARK: - UI Components
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = UIColor(named: "colors/Primary/Light") ?? .white
        button.backgroundColor = UIColor.clear
        button.isUserInteractionEnabled = true
        button.isEnabled = true
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return button
    }()
    
    private let petView = PetAvatarView()
    
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
    
    // variables

    private var gradientLayer: CAGradientLayer?
    private var animationTimer: Timer?
    private var isAnimating = false
    
    // Speech Recognition Properties
    private lazy var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private lazy var audioEngine = AVAudioEngine()
    private var isRecording = false
    private var audioLevelTimer: Timer?
    
    // 3D Model Properties
    private var idleAnimation: SCNAction?
    
    // lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setup3DPenguin()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startBlobAnimation()
        requestSpeechPermission()
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
        view.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-400") ?? UIColor(red: 0.38, green: 0.38, blue: 1.0, alpha: 1.0)
        
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            (UIColor(named: "colors/Blue&Shades/blue-400") ?? UIColor(red: 0.38, green: 0.38, blue: 1.0, alpha: 1.0)).cgColor,
            (UIColor(named: "colors/Blue&Shades/blue-300") ?? UIColor(red: 0.48, green: 0.48, blue: 1.0, alpha: 1.0)).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        view.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        petView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(petView)
        view.addSubview(transcriptionLabel)
        view.addSubview(animatedBlobContainer)
        view.addSubview(micButton)
        view.addSubview(backButton)
        
        animatedBlobContainer.addSubview(outerBlob)
        animatedBlobContainer.addSubview(middleBlob)
        animatedBlobContainer.addSubview(innerBlob)
        animatedBlobContainer.addSubview(centerDot)
  
        view.bringSubviewToFront(micButton)
        view.bringSubviewToFront(backButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Back Button
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 50),
            backButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Penguin 3D Scene View 
            petView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            petView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            petView.widthAnchor.constraint(equalToConstant: 350),
            petView.heightAnchor.constraint(equalToConstant: 350),
            
            // Transcription Label 
            transcriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            transcriptionLabel.topAnchor.constraint(equalTo: petView.bottomAnchor, constant: 30),
            transcriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            transcriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Mic Button 
            micButton.topAnchor.constraint(equalTo: transcriptionLabel.bottomAnchor, constant: 60),
            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 60),
            micButton.heightAnchor.constraint(equalToConstant: 60),
            
            // Animated Blob Container 
            animatedBlobContainer.centerXAnchor.constraint(equalTo: micButton.centerXAnchor),
            animatedBlobContainer.centerYAnchor.constraint(equalTo: micButton.centerYAnchor),
            animatedBlobContainer.widthAnchor.constraint(equalToConstant: 120),
            animatedBlobContainer.heightAnchor.constraint(equalToConstant: 120),
            
            // Outer Blob
            outerBlob.centerXAnchor.constraint(equalTo: animatedBlobContainer.centerXAnchor),
            outerBlob.centerYAnchor.constraint(equalTo: animatedBlobContainer.centerYAnchor),
            outerBlob.widthAnchor.constraint(equalToConstant: 120),
            outerBlob.heightAnchor.constraint(equalToConstant: 120),
            
            // Middle Blob
            middleBlob.centerXAnchor.constraint(equalTo: animatedBlobContainer.centerXAnchor),
            middleBlob.centerYAnchor.constraint(equalTo: animatedBlobContainer.centerYAnchor),
            middleBlob.widthAnchor.constraint(equalToConstant: 90),
            middleBlob.heightAnchor.constraint(equalToConstant: 90),
            
            // Inner Blob
            innerBlob.centerXAnchor.constraint(equalTo: animatedBlobContainer.centerXAnchor),
            innerBlob.centerYAnchor.constraint(equalTo: animatedBlobContainer.centerYAnchor),
            innerBlob.widthAnchor.constraint(equalToConstant: 70),
            innerBlob.heightAnchor.constraint(equalToConstant: 70),
            
            // Center Dot
            centerDot.centerXAnchor.constraint(equalTo: animatedBlobContainer.centerXAnchor),
            centerDot.centerYAnchor.constraint(equalTo: animatedBlobContainer.centerYAnchor),
            centerDot.widthAnchor.constraint(equalToConstant: 20),
            centerDot.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        micButton.addTarget(self, action: #selector(micButtonTapped), for: .touchUpInside)
    }
    
    // 3d penguin stuff

    private func setup3DPenguin() {
        petView.enableCameraControl(true)
        
        petView.configure(scale: petBaseScale, position: SCNVector3(0, -1.8, 0))
    }
    
    private func animatePenguinForVoice(intensity: Float) {
        guard let penguin = petView.penguinNode else { return }
        
        
        // Scale animation based on voice intensity
        let scale = CGFloat(petBaseScale) * (1.0 + (CGFloat(intensity) * 0.3))
        let scaleAction = SCNAction.scale(to: scale, duration: 0.1)
        penguin.runAction(scaleAction, forKey: "voiceScale")
        
        // Slight tilt when speaking
        if intensity > 0.3 {
            let tiltAngle = CGFloat(intensity) * 0.2
            let tiltAction = SCNAction.rotateBy(x: tiltAngle, y: 0, z: 0, duration: 0.2)
            penguin.runAction(tiltAction, forKey: "voiceTilt")
        }
    }
    
    // blob animation

    private func startBlobAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        
        outerBlob.alpha = 0
        middleBlob.alpha = 0
        innerBlob.alpha = 0
        centerDot.alpha = 0
    }
    
    private func stopBlobAnimation() {
        isAnimating = false
        animationTimer?.invalidate()
        animationTimer = nil
        
        outerBlob.layer.removeAllAnimations()
        middleBlob.layer.removeAllAnimations()
        innerBlob.layer.removeAllAnimations()
        centerDot.layer.removeAllAnimations()
    }
    
    private func animateBlobPulse() {
        guard isRecording else { return }
        
        UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.outerBlob.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.outerBlob.alpha = 0.3
        })
        
        UIView.animate(withDuration: 1.5, delay: 0.2, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.middleBlob.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.middleBlob.alpha = 0.5
        })
        
        UIView.animate(withDuration: 1.0, delay: 0.4, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.innerBlob.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.innerBlob.alpha = 0.9
        })
        
        UIView.animate(withDuration: 0.8, delay: 0.6, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.centerDot.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
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
                    self?.transcriptionLabel.text = "Speech recognition denied"
                case .restricted:
                    self?.transcriptionLabel.text = "Speech recognition restricted"
                case .notDetermined:
                    self?.transcriptionLabel.text = "Speech recognition not available"
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func startRecording() {
        guard !isRecording else { return }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            recognitionRequest.append(buffer)
            self?.processAudioLevel(buffer: buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start failed: \(error)")
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    let transcription = result.bestTranscription.formattedString
                    self?.transcriptionLabel.text = transcription
                }
                
                if error != nil || result?.isFinal == true {
                    self?.stopRecording()
                }
            }
        }
        
        isRecording = true
        updateMicButton()
        transcriptionLabel.text = "Listening..."
        showBlobForRecording()
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
        
        hideBlobAfterRecording()
    }
    
    private func processAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0
        
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }
        
        let averageLevel = sum / Float(frameLength)
        let normalizedLevel = min(averageLevel * 10, 1.0)
        
        DispatchQueue.main.async { [weak self] in
            self?.animateBlobForAudio(level: normalizedLevel)
        }
    }
    
    private func animateBlobForAudio(level: Float) {
        guard isRecording else { return }
        
        let intensity = CGFloat(level)
        let scale = 1.0 + (intensity * 0.5)
        
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: {
            self.outerBlob.transform = CGAffineTransform(scaleX: scale * 1.1, y: scale * 1.1)
            self.middleBlob.transform = CGAffineTransform(scaleX: scale * 1.2, y: scale * 1.2)
            self.innerBlob.transform = CGAffineTransform(scaleX: scale * 1.3, y: scale * 1.3)
            self.centerDot.transform = CGAffineTransform(scaleX: scale * 1.4, y: scale * 1.4)
            
            self.outerBlob.alpha = 0.1 + (intensity * 0.3)
            self.middleBlob.alpha = 0.2 + (intensity * 0.4)
            self.innerBlob.alpha = 0.8 + (intensity * 0.2)
            self.centerDot.alpha = 1.0
        })
        
        animatePenguinForVoice(intensity: level)
    }
    
    private func showBlobForRecording() {
        UIView.animate(withDuration: 0.3) {
            self.outerBlob.alpha = 0.1
            self.middleBlob.alpha = 0.2
            self.innerBlob.alpha = 0.8
            self.centerDot.alpha = 1.0
        }
        animateBlobPulse()
    }
    
    private func hideBlobAfterRecording() {
        UIView.animate(withDuration: 0.3) {
            self.outerBlob.alpha = 0
            self.middleBlob.alpha = 0
            self.innerBlob.alpha = 0
            self.centerDot.alpha = 0
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
    
    // MARK: - Actions
    @objc private func micButtonTapped() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
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
    
    @objc private func backButtonTapped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        UIView.animate(withDuration: 0.1, animations: {
            self.backButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.backButton.transform = .identity
            }
        }
        
        if let navController = navigationController {
            navController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
