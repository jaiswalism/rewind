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
import Combine

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
    
    // MARK: - ViewModels
    private let petViewModel = PetViewModel()
    
    // MARK: - UI Components
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        var config = UIButton.Configuration.plain()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        config.image = UIImage(systemName: "chevron.left", withConfiguration: imageConfig)
        config.baseForegroundColor = UIColor(named: "colors/Primary/Light") ?? .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        button.configuration = config
        
        button.backgroundColor = UIColor.clear
        button.isUserInteractionEnabled = true
        button.isEnabled = true
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
    // Use system default locale to match Siri language settings
    private lazy var speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private lazy var audioEngine = AVAudioEngine()
    private var isRecording = false
    private var audioLevelTimer: Timer?
    
    // Permission states
    private var micPermissionGranted = false
    private var speechPermissionGranted = false
    
    // 3D Model Properties
    private var idleAnimation: SCNAction?
    
    // TTS Properties
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setup3DPenguin()
        setupAudioRouteChangeNotifications()
        printAudioDiagnostics()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startBlobAnimation()
        requestSpeechPermission()
    }
    
    // MARK: - Audio Diagnostics
    private func printAudioDiagnostics() {
        print("[PetTalking] ========== AUDIO DIAGNOSTICS ==========")
        
        #if targetEnvironment(simulator)
        print("[PetTalking] Running on iOS SIMULATOR")
        print("[PetTalking] NOTE: Simulator uses Mac's microphone. Ensure:")
        print("[PetTalking]   1. Mac's System Preferences > Security & Privacy > Microphone allows Xcode/Simulator")
        print("[PetTalking]   2. Mac has a working audio input device selected")
        print("[PetTalking]   3. Try: System Preferences > Sound > Input - check if input level moves")
        #else
        print("[PetTalking] Running on PHYSICAL DEVICE")
        #endif
        
        let audioSession = AVAudioSession.sharedInstance()
        print("[PetTalking] Current category: \(audioSession.category.rawValue)")
        print("[PetTalking] Current mode: \(audioSession.mode.rawValue)")
        print("[PetTalking] Input available: \(audioSession.isInputAvailable)")
        print("[PetTalking] Sample rate: \(audioSession.sampleRate)")
        print("[PetTalking] Input channels: \(audioSession.inputNumberOfChannels)")
        
        if let inputs = audioSession.availableInputs {
            print("[PetTalking] Available audio inputs (\(inputs.count)):")
            for (index, input) in inputs.enumerated() {
                print("[PetTalking]   [\(index)] \(input.portName) (\(input.portType.rawValue))")
            }
        } else {
            print("[PetTalking] WARNING: No available audio inputs!")
        }
        
        if let currentInput = audioSession.currentRoute.inputs.first {
            print("[PetTalking] Current input: \(currentInput.portName) (\(currentInput.portType.rawValue))")
        } else {
            print("[PetTalking] WARNING: No current input route!")
        }
        
        print("[PetTalking] ================================================")
    }
    
    private func setupAudioRouteChangeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    @objc private func handleAudioRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        print("[PetTalking] Audio route changed: \(reason.rawValue)")
        
        switch reason {
        case .newDeviceAvailable:
            print("[PetTalking] New audio device available")
            printAudioDiagnostics()
        case .oldDeviceUnavailable:
            print("[PetTalking] Audio device removed")
            if isRecording {
                DispatchQueue.main.async {
                    self.stopRecording()
                    self.transcriptionLabel.text = "Audio device disconnected"
                }
            }
        case .categoryChange:
            print("[PetTalking] Audio category changed")
        default:
            break
        }
    }
    
    @objc private func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("[PetTalking] Audio interruption BEGAN")
            if isRecording {
                DispatchQueue.main.async {
                    self.stopRecording()
                    self.transcriptionLabel.text = "Interrupted"
                }
            }
        case .ended:
            print("[PetTalking] Audio interruption ENDED")
        @unknown default:
            break
        }
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
        print("[PetTalking] Requesting permissions...")
        
        // Request Speech Recognition Permission
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            print("[PetTalking] Speech recognition authorization status: \(authStatus.rawValue)")
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("[PetTalking] Speech recognition AUTHORIZED")
                    self?.speechPermissionGranted = true
                    self?.updatePermissionStatus()
                case .denied:
                    print("[PetTalking] Speech recognition DENIED")
                    self?.speechPermissionGranted = false
                    self?.transcriptionLabel.text = "Speech recognition denied"
                case .restricted:
                    print("[PetTalking] Speech recognition RESTRICTED")
                    self?.speechPermissionGranted = false
                    self?.transcriptionLabel.text = "Speech recognition restricted"
                case .notDetermined:
                    print("[PetTalking] Speech recognition NOT DETERMINED")
                    self?.speechPermissionGranted = false
                    self?.transcriptionLabel.text = "Speech recognition not available"
                @unknown default:
                    break
                }
            }
        }
        
        // Request Microphone Permission
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] allowed in
                print("[PetTalking] Microphone permission (iOS 17+): \(allowed ? "GRANTED" : "DENIED")")
                DispatchQueue.main.async {
                    self?.micPermissionGranted = allowed
                    if !allowed {
                        self?.transcriptionLabel.text = "Microphone permission needed"
                    } else {
                        self?.updatePermissionStatus()
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
                print("[PetTalking] Microphone permission: \(allowed ? "GRANTED" : "DENIED")")
                DispatchQueue.main.async {
                    self?.micPermissionGranted = allowed
                    if !allowed {
                        self?.transcriptionLabel.text = "Microphone permission needed"
                    } else {
                        self?.updatePermissionStatus()
                    }
                }
            }
        }
    }
    
    private func updatePermissionStatus() {
        if micPermissionGranted && speechPermissionGranted {
            print("[PetTalking] All permissions granted - Ready to record")
            transcriptionLabel.text = "Tap to start talking..."
        }
    }
    
    private func verifyPermissionsBeforeRecording() -> Bool {
        print("[PetTalking] Verifying permissions before recording...")
        
        // Check Speech Recognition
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        print("[PetTalking] Speech recognition status: \(speechStatus.rawValue)")
        guard speechStatus == .authorized else {
            print("[PetTalking] ERROR: Speech recognition not authorized")
            transcriptionLabel.text = "Speech permission required"
            return false
        }
        
        // Check Microphone
        var micGranted = false
        if #available(iOS 17.0, *) {
            let micStatus = AVAudioApplication.shared.recordPermission
            micGranted = (micStatus == .granted)
            print("[PetTalking] Microphone permission status (iOS 17+): \(micStatus)")
        } else {
            let micStatus = AVAudioSession.sharedInstance().recordPermission
            micGranted = (micStatus == .granted)
            print("[PetTalking] Microphone permission status: \(micStatus.rawValue)")
        }
        guard micGranted else {
            print("[PetTalking] ERROR: Microphone permission not granted")
            transcriptionLabel.text = "Microphone permission required"
            return false
        }
        
        // Check SpeechRecognizer availability
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("[PetTalking] ERROR: Speech recognizer not available")
            transcriptionLabel.text = "Speech recognition unavailable"
            return false
        }
        print("[PetTalking] Speech recognizer available: \(recognizer.isAvailable)")
        
        print("[PetTalking] All permissions verified - ready to record")
        return true
    }
    
    private func startRecording() {
        print("[PetTalking] ========== START RECORDING ==========")
        guard !isRecording else {
            print("[PetTalking] Already recording, ignoring start request")
            return
        }
        
        // Verify permissions before starting
        guard verifyPermissionsBeforeRecording() else {
            print("[PetTalking] ERROR: Permissions not verified, aborting recording")
            return
        }
        
        // Stop any existing recording first
        if audioEngine.isRunning {
            print("[PetTalking] WARNING: Audio engine already running, stopping first")
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // Cancel any previous recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Setup audio session - Use playAndRecord for compatibility with playback
        let audioSession = AVAudioSession.sharedInstance()
        print("[PetTalking] Configuring audio session...")
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP])
            print("[PetTalking] Audio session category set: playAndRecord, mode: measurement")
            
            // CRITICAL: Activate the session BEFORE checking inputs
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("[PetTalking] Audio session ACTIVATED successfully")
            
            // Explicitly select the preferred input (important for Simulator)
            if let availableInputs = audioSession.availableInputs, !availableInputs.isEmpty {
                print("[PetTalking] Found \(availableInputs.count) available input(s)")
                
                let preferredInput = availableInputs.first { input in
                    input.portType == .builtInMic
                } ?? availableInputs.first
                
                if let input = preferredInput {
                    try audioSession.setPreferredInput(input)
                    print("[PetTalking] Preferred input set to: \(input.portName) (\(input.portType.rawValue))")
                }
            } else {
                print("[PetTalking] WARNING: No available inputs found!")
                #if targetEnvironment(simulator)
                print("[PetTalking] SIMULATOR: Check that your Mac's microphone is enabled and Xcode has microphone permission")
                #endif
            }
            
            print("[PetTalking] Sample rate: \(audioSession.sampleRate)")
            print("[PetTalking] Input available: \(audioSession.isInputAvailable)")
            print("[PetTalking] Input channels: \(audioSession.inputNumberOfChannels)")
            
            let currentRoute = audioSession.currentRoute
            print("[PetTalking] Current audio route inputs: \(currentRoute.inputs.map { $0.portName })")
            print("[PetTalking] Current audio route outputs: \(currentRoute.outputs.map { $0.portName })")
            
            if let inputDataSource = audioSession.inputDataSource {
                print("[PetTalking] Input data source: \(inputDataSource.dataSourceName)")
            }
            
            guard audioSession.isInputAvailable else {
                print("[PetTalking] ERROR: No audio input available after activation!")
                transcriptionLabel.text = "No microphone available"
                return
            }
        } catch {
            print("[PetTalking] ERROR: Audio session setup failed: \(error.localizedDescription)")
            print("[PetTalking] Error details: \(error)")
            transcriptionLabel.text = "Audio setup failed"
            return
        }
        
        // Setup recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("[PetTalking] ERROR: Could not create recognition request")
            transcriptionLabel.text = "Recognition setup failed"
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        print("[PetTalking] Recognition request created")
        
        // Setup Audio Engine Input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // CRITICAL: Validate recording format
        print("[PetTalking] Recording format: \(recordingFormat)")
        print("[PetTalking] Format sample rate: \(recordingFormat.sampleRate)")
        print("[PetTalking] Format channel count: \(recordingFormat.channelCount)")
        
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("[PetTalking] ERROR: Invalid recording format - sample rate or channels is 0")
            print("[PetTalking] Format details: \(recordingFormat.description)")
            print("[PetTalking] This typically means no audio input is available")
            
            #if targetEnvironment(simulator)
            print("[PetTalking] ==================== SIMULATOR TROUBLESHOOTING ====================")
            print("[PetTalking] The iOS Simulator uses your Mac's microphone.")
            print("[PetTalking] Please check the following:")
            print("[PetTalking]   1. System Preferences > Security & Privacy > Privacy > Microphone")
            print("[PetTalking]      - Ensure Xcode is listed and ENABLED")
            print("[PetTalking]   2. System Preferences > Sound > Input")
            print("[PetTalking]      - Select a working input device")
            print("[PetTalking]      - Check if input level indicator moves when you speak")
            print("[PetTalking]   3. Try restarting the Simulator")
            print("[PetTalking]   4. Try running on a physical device instead")
            print("[PetTalking] =================================================================")
            transcriptionLabel.text = "Simulator: Check Mac microphone"
            #else
            transcriptionLabel.text = "No audio input available"
            #endif
            
            // Try to show available inputs for debugging
            if let availableInputs = audioSession.availableInputs {
                print("[PetTalking] Available inputs: \(availableInputs.map { "\($0.portName) (\($0.portType.rawValue))" })")
            } else {
                print("[PetTalking] No available inputs detected")
            }
            
            // Log current route
            let currentRoute = audioSession.currentRoute
            print("[PetTalking] Current route inputs: \(currentRoute.inputs)")
            print("[PetTalking] Current route outputs: \(currentRoute.outputs)")
            
            return
        }
        
        // Remove existing tap and install new one
        inputNode.removeTap(onBus: 0)
        print("[PetTalking] Installing audio tap...")
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            recognitionRequest.append(buffer)
            self?.processAudioLevel(buffer: buffer)
        }
        print("[PetTalking] Audio tap installed")
        
        // Start audio engine
        audioEngine.prepare()
        print("[PetTalking] Audio engine prepared")
        
        do {
            try audioEngine.start()
            print("[PetTalking] Audio engine STARTED successfully")
        } catch {
            print("[PetTalking] ERROR: Audio engine start failed: \(error.localizedDescription)")
            transcriptionLabel.text = "Audio engine failed to start"
            inputNode.removeTap(onBus: 0)
            return
        }
        
        // Start Recognition Task
        print("[PetTalking] Starting recognition task...")
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let error = error {
                print("[PetTalking] Recognition error: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                if let result = result {
                    let transcription = result.bestTranscription.formattedString
                    self?.transcriptionLabel.text = transcription
                    print("[PetTalking] Transcription: \(transcription)")
                }
                
                if error != nil || result?.isFinal == true {
                    print("[PetTalking] Recognition ended, stopping recording")
                    self?.stopRecording()
                }
            }
        }
        
        if recognitionTask == nil {
            print("[PetTalking] WARNING: Recognition task is nil - speech recognizer may be unavailable")
        } else {
            print("[PetTalking] Recognition task started")
        }
        
        isRecording = true
        updateMicButton()
        transcriptionLabel.text = "Listening..."
        showBlobForRecording()
        print("[PetTalking] Recording started successfully")
    }
    
    private func stopRecording() {
        print("[PetTalking] ========== STOP RECORDING ==========")
        guard isRecording else {
            print("[PetTalking] Not currently recording, ignoring stop request")
            return
        }
        
        print("[PetTalking] Stopping audio engine...")
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        print("[PetTalking] Audio engine stopped, tap removed")
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        print("[PetTalking] Recognition request ended, task cancelled")
        
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        
        isRecording = false
        updateMicButton()
        
        // Get transcription before resetting
        let currentText = transcriptionLabel.text ?? ""
        
        if currentText == "Listening..." {
            transcriptionLabel.text = "Tap to start talking..."
        } else if !currentText.isEmpty && currentText != "Tap to start talking..." {
            // Send transcription to backend
            print("[PetTalking] Sending transcription to backend: \(currentText)")
            sendToBackend(text: currentText)
        }
        
        hideBlobAfterRecording()
        print("[PetTalking] Recording stopped successfully")
    }
    
    private func sendToBackend(text: String) {
        transcriptionLabel.text = "Thinking..."
        
        Task {
            do {
                let (response, _, _) = try await petViewModel.sendMessage(text)
                await MainActor.run {
                    self.transcriptionLabel.text = response
                    self.speak(text: response)
                }
            } catch {
                await MainActor.run {
                    print("Chat error: \(error)")
                    self.transcriptionLabel.text = "Thinking failed."
                }
            }
        }
    }
    
    private func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.2 // Slightly higher pitch for cute penguin
        
        // Ensure audio session is correct for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error for playback: \(error)")
        }
        
        speechSynthesizer.speak(utterance)
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
            if let text = transcriptionLabel.text, !text.isEmpty, text != "Listening...", text != "Tap to start talking..." {
                 sendToBackend(text: text)
            }
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
