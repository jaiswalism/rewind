//
//  PetTalkingViewController.swift
//  Rewind
//

import UIKit
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

    // MARK: - Services
    private let voiceService = PetVoiceService.shared

    // MARK: - Session State
    private enum SessionState {
        case connecting
        case listening      // Mic open, streaming continuously
        case petSpeaking    // Gemini is sending audio
        case ended
    }
    private var sessionState: SessionState = .connecting

    // MARK: - Interaction Mode
    private enum InteractionMode { case voice, text }
    private var currentMode: InteractionMode = .voice

    // MARK: - Permission
    private var micPermissionGranted = false

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
        button.backgroundColor = .clear
        return button
    }()

    private let modeSwitchButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        config.image = UIImage(systemName: "keyboard", withConfiguration: imageConfig)
        config.baseForegroundColor = UIColor(named: "colors/Primary/Light") ?? .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        button.configuration = config
        button.backgroundColor = .clear
        return button
    }()

    private let petView = PetAvatarView()

    // Blob layers
    private let animatedBlobContainer: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let outerBlob: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.1); return v
    }()
    private let middleBlob: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.2); return v
    }()
    private let innerBlob: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = (UIColor(named: "colors/Primary/Light") ?? .white).withAlphaComponent(0.8); return v
    }()
    private let centerDot: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(named: "colors/Primary/Dark") ?? .blue; return v
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Connecting..."
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = UIColor(named: "colors/Primary/Light") ?? .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.alpha = 0.8
        return label
    }()

    /// In voice mode this is the "End Session" hang-up button.
    /// In text mode it is hidden.
    private let endCallButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        let image = UIImage(systemName: "phone.down.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.systemRed.withAlphaComponent(0.85)
        button.layer.cornerRadius = 30
        return button
    }()

    // Text mode UI
    private let textInputContainer: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true; return v
    }()
    private let textInputField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = "Type a message..."
        field.font = UIFont.systemFont(ofSize: 16)
        field.textColor = .white
        field.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        field.layer.cornerRadius = 20
        field.layer.masksToBounds = true
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        field.leftViewMode = .always
        field.returnKeyType = .send
        field.isHidden = true
        return field
    }()
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        button.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(named: "colors/Primary/Light") ?? .white
        button.backgroundColor = .clear
        button.isEnabled = false
        button.alpha = 0.5
        button.isHidden = true
        return button
    }()

    // MARK: - Visual State

    private var gradientLayer: CAGradientLayer?
    private var isAnimating = false
    private var idleAnimation: SCNAction?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setup3DPenguin()
        setupAudioRouteChangeNotifications()
        setupVoiceCallbacks()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        Task { [weak self] in
            await MainActor.run {
                self?.voiceService.disconnect()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startBlobAnimation()
        requestMicPermissionThenConnect()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopBlobAnimation()
        voiceService.disconnect()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
        outerBlob.layer.cornerRadius = outerBlob.bounds.width / 2
        middleBlob.layer.cornerRadius = middleBlob.bounds.width / 2
        innerBlob.layer.cornerRadius = innerBlob.bounds.width / 2
        centerDot.layer.cornerRadius = centerDot.bounds.width / 2
    }

    // MARK: - Voice Service Callbacks

    private func setupVoiceCallbacks() {
        voiceService.onConnected = { [weak self] in
            print("[PetTalking] ✅ Connected")
            self?.startLiveSession()
        }

        voiceService.onDisconnected = { [weak self] in
            print("[PetTalking] ❌ Disconnected")
            self?.sessionState = .ended
            self?.statusLabel.text = "Disconnected"
            self?.hideBlobAnimated()
        }

        voiceService.onTranscription = { [weak self] text in
            // Show what the pet said (text transcript alongside audio)
            self?.statusLabel.text = text
        }

        voiceService.onPetStartedSpeaking = { [weak self] in
            guard let self else { return }
            self.sessionState = .petSpeaking
            self.statusLabel.text = "Pet is speaking..."
            self.showBlobAnimated()
        }

        voiceService.onResponseComplete = { [weak self] in
            guard let self else { return }
            // Pet finished — back to listening
            self.sessionState = .listening
            UIView.animate(withDuration: 0.3) {
                self.statusLabel.text = "Listening..."
            }
        }

        voiceService.onAudioLevel = { [weak self] level in
            // Drive blob in real time from mic RMS
            self?.animateBlobForLevel(level)
        }

        voiceService.onError = { [weak self] error in
            print("[PetTalking] ⚠️ \(error)")
            self?.statusLabel.text = "Connection issue — tap to retry"
        }
    }

    // MARK: - Connection Flow

    private func requestMicPermissionThenConnect() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async { self?.handleMicPermission(granted) }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async { self?.handleMicPermission(granted) }
            }
        }
    }

    private func handleMicPermission(_ granted: Bool) {
        micPermissionGranted = granted
        guard granted else {
            statusLabel.text = "Microphone permission required"
            return
        }
        Task { await connectToVoiceService() }
    }

    private func connectToVoiceService() async {
        do {
            try await voiceService.connect()
        } catch {
            print("[PetTalking] Failed to connect: \(error)")
            statusLabel.text = "Failed to connect"
        }
    }

    /// Called once voiceService.onConnected fires — starts mic streaming immediately.
    private func startLiveSession() {
        guard micPermissionGranted, currentMode == .voice else { return }
        sessionState = .listening
        statusLabel.text = "Listening..."
        showBlobAnimated()

        Task {
            do {
                try await voiceService.startStreaming()
                print("[PetTalking] 🎙️ Live streaming started")
            } catch {
                print("[PetTalking] Failed to start streaming: \(error)")
                await MainActor.run { self.statusLabel.text = "Audio error" }
            }
        }
    }

    // MARK: - 3D Penguin

    private func setup3DPenguin() {
        petView.enableCameraControl(true)
        petView.configure(scale: petBaseScale, position: SCNVector3(0, -1.8, 0))
    }

    private func animatePenguinForLevel(_ level: Float) {
        guard let penguin = petView.penguinNode else { return }
        let scale = CGFloat(petBaseScale) * (1.0 + CGFloat(level) * 0.3)
        penguin.runAction(SCNAction.scale(to: scale, duration: 0.1), forKey: "voiceScale")
    }

    // MARK: - Blob Animation

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
        outerBlob.layer.removeAllAnimations()
        middleBlob.layer.removeAllAnimations()
        innerBlob.layer.removeAllAnimations()
        centerDot.layer.removeAllAnimations()
    }

    private func showBlobAnimated() {
        UIView.animate(withDuration: 0.3) {
            self.outerBlob.alpha = 0.15
            self.middleBlob.alpha = 0.3
            self.innerBlob.alpha = 0.85
            self.centerDot.alpha = 1.0
        }
    }

    private func hideBlobAnimated() {
        UIView.animate(withDuration: 0.3) {
            self.outerBlob.alpha = 0
            self.middleBlob.alpha = 0
            self.innerBlob.alpha = 0
            self.centerDot.alpha = 0
        }
        outerBlob.transform = .identity
        middleBlob.transform = .identity
        innerBlob.transform = .identity
        centerDot.transform = .identity
    }

    /// Drives the blob layers directly from the real-time mic RMS level [0...1].
    private func animateBlobForLevel(_ level: Float) {
        let intensity = CGFloat(level)
        let scale = 1.0 + intensity * 0.5

        UIView.animate(withDuration: 0.08, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.outerBlob.transform = CGAffineTransform(scaleX: scale * 1.1, y: scale * 1.1)
            self.middleBlob.transform = CGAffineTransform(scaleX: scale * 1.2, y: scale * 1.2)
            self.innerBlob.transform = CGAffineTransform(scaleX: scale * 1.3, y: scale * 1.3)
            self.centerDot.transform = CGAffineTransform(scaleX: scale * 1.4, y: scale * 1.4)

            self.outerBlob.alpha = 0.1 + intensity * 0.3
            self.middleBlob.alpha = 0.2 + intensity * 0.4
            self.innerBlob.alpha = 0.75 + intensity * 0.25
            self.centerDot.alpha = 1.0
        }

        animatePenguinForLevel(level)
    }

    // MARK: - Mode Switching

    private func switchToTextMode() {
        currentMode = .text
        voiceService.stopStreaming()

        endCallButton.isHidden = true
        animatedBlobContainer.isHidden = true
        textInputContainer.isHidden = false
        textInputField.isHidden = false
        sendButton.isHidden = false

        let imageConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        modeSwitchButton.setImage(UIImage(systemName: "mic.fill", withConfiguration: imageConfig), for: .normal)

        statusLabel.text = "Type a message..."
        textInputField.becomeFirstResponder()
    }

    private func switchToVoiceMode() {
        currentMode = .voice

        textInputContainer.isHidden = true
        textInputField.isHidden = true
        sendButton.isHidden = true
        textInputField.resignFirstResponder()

        endCallButton.isHidden = false
        animatedBlobContainer.isHidden = false

        let imageConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        modeSwitchButton.setImage(UIImage(systemName: "keyboard", withConfiguration: imageConfig), for: .normal)

        // Resume streaming if we're connected
        if sessionState == .ended || sessionState == .connecting { return }
        statusLabel.text = "Listening..."
        Task {
            try? await voiceService.startStreaming()
        }
    }

    // MARK: - Actions

    @objc private func endCallButtonTapped() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        voiceService.disconnect()
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func modeSwitchButtonTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if currentMode == .voice { switchToTextMode() } else { switchToVoiceMode() }
    }

    @objc private func sendButtonTapped() {
        guard let text = textInputField.text, !text.isEmpty else { return }
        statusLabel.text = "Pet is thinking..."
        textInputField.text = ""
        textInputField.resignFirstResponder()
        Task {
            do {
                let userId = UserDefaults.standard.string(forKey: Constants.UserDefaults.currentUserID)
                let currentState = await MainActor.run { PetCompanionService.shared.currentState }
                let context = PetInferenceContext(
                    timeOfDay: currentTimeOfDay(),
                    daysInactive: 0,
                    state: currentState.map { PetCompanionStateSnapshot(from: $0) }
                )

                let request = PetInferenceRequest(
                    type: .message,
                    content: text,
                    explicitRequest: true,
                    context: context,
                    userId: userId
                )

                let response = try await PetCompanionService.shared.infer(request)
                await MainActor.run {
                    self.statusLabel.text = response.textResponse ?? PetConstants.fallbackText
                }
            } catch {
                await MainActor.run { self.statusLabel.text = "Failed to send" }
            }
        }
    }

    private func currentTimeOfDay() -> PetTimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return .morning
        case 12..<17:
            return .afternoon
        case 17..<21:
            return .evening
        default:
            return .night
        }
    }

    @objc private func backButtonTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIView.animate(withDuration: 0.1) { self.backButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) } completion: { _ in
            UIView.animate(withDuration: 0.1) { self.backButton.transform = .identity }
        }
        voiceService.disconnect()
        if let nav = navigationController { nav.popViewController(animated: true) } else { dismiss(animated: true) }
    }

    // MARK: - Audio Route Change Handling

    private func setupAudioRouteChangeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioRouteChange),
                                               name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioInterruption),
                                               name: AVAudioSession.interruptionNotification, object: nil)
    }

    @objc private func handleAudioRouteChange(notification: Notification) {
        guard let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        if reason == .oldDeviceUnavailable {
            print("[PetTalking] Audio device removed")
        }
    }

    @objc private func handleAudioInterruption(notification: Notification) {
        guard let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        if type == .began {
            print("[PetTalking] Audio interruption — pausing")
        }
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
        view.addSubview(statusLabel)
        view.addSubview(animatedBlobContainer)
        view.addSubview(endCallButton)
        view.addSubview(backButton)
        view.addSubview(modeSwitchButton)

        view.addSubview(textInputContainer)
        textInputContainer.addSubview(textInputField)
        textInputContainer.addSubview(sendButton)

        animatedBlobContainer.addSubview(outerBlob)
        animatedBlobContainer.addSubview(middleBlob)
        animatedBlobContainer.addSubview(innerBlob)
        animatedBlobContainer.addSubview(centerDot)

        view.bringSubviewToFront(endCallButton)
        view.bringSubviewToFront(backButton)
        view.bringSubviewToFront(modeSwitchButton)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 50),
            backButton.heightAnchor.constraint(equalToConstant: 50),

            modeSwitchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            modeSwitchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            modeSwitchButton.widthAnchor.constraint(equalToConstant: 50),
            modeSwitchButton.heightAnchor.constraint(equalToConstant: 50),

            petView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            petView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            petView.widthAnchor.constraint(equalToConstant: 350),
            petView.heightAnchor.constraint(equalToConstant: 350),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: petView.bottomAnchor, constant: 30),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            // End call button replaces the old mic button
            endCallButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 60),
            endCallButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            endCallButton.widthAnchor.constraint(equalToConstant: 60),
            endCallButton.heightAnchor.constraint(equalToConstant: 60),

            animatedBlobContainer.centerXAnchor.constraint(equalTo: endCallButton.centerXAnchor),
            animatedBlobContainer.centerYAnchor.constraint(equalTo: endCallButton.centerYAnchor),
            animatedBlobContainer.widthAnchor.constraint(equalToConstant: 120),
            animatedBlobContainer.heightAnchor.constraint(equalToConstant: 120),

            outerBlob.centerXAnchor.constraint(equalTo: animatedBlobContainer.centerXAnchor),
            outerBlob.centerYAnchor.constraint(equalTo: animatedBlobContainer.centerYAnchor),
            outerBlob.widthAnchor.constraint(equalToConstant: 120),
            outerBlob.heightAnchor.constraint(equalToConstant: 120),

            middleBlob.centerXAnchor.constraint(equalTo: animatedBlobContainer.centerXAnchor),
            middleBlob.centerYAnchor.constraint(equalTo: animatedBlobContainer.centerYAnchor),
            middleBlob.widthAnchor.constraint(equalToConstant: 90),
            middleBlob.heightAnchor.constraint(equalToConstant: 90),

            innerBlob.centerXAnchor.constraint(equalTo: animatedBlobContainer.centerXAnchor),
            innerBlob.centerYAnchor.constraint(equalTo: animatedBlobContainer.centerYAnchor),
            innerBlob.widthAnchor.constraint(equalToConstant: 70),
            innerBlob.heightAnchor.constraint(equalToConstant: 70),

            centerDot.centerXAnchor.constraint(equalTo: animatedBlobContainer.centerXAnchor),
            centerDot.centerYAnchor.constraint(equalTo: animatedBlobContainer.centerYAnchor),
            centerDot.widthAnchor.constraint(equalToConstant: 20),
            centerDot.heightAnchor.constraint(equalToConstant: 20),

            textInputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textInputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textInputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            textInputContainer.heightAnchor.constraint(equalToConstant: 50),

            textInputField.leadingAnchor.constraint(equalTo: textInputContainer.leadingAnchor),
            textInputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            textInputField.centerYAnchor.constraint(equalTo: textInputContainer.centerYAnchor),
            textInputField.heightAnchor.constraint(equalToConstant: 44),

            sendButton.trailingAnchor.constraint(equalTo: textInputContainer.trailingAnchor),
            sendButton.centerYAnchor.constraint(equalTo: textInputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        endCallButton.addTarget(self, action: #selector(endCallButtonTapped), for: .touchUpInside)
        modeSwitchButton.addTarget(self, action: #selector(modeSwitchButtonTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        textInputField.delegate = self
    }
}

// MARK: - UITextFieldDelegate

extension PetTalkingViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return true }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        sendButton.isEnabled = !updatedText.isEmpty
        sendButton.alpha = updatedText.isEmpty ? 0.5 : 1.0
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendButtonTapped()
        return true
    }
}
