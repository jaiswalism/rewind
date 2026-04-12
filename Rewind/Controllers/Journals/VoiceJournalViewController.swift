import UIKit
import AVFoundation
import Speech
import Combine

class VoiceJournalViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var waveformStackView: UIStackView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var checkButton: UIButton!
    
    // MARK: - Properties
    private var isRecording = false
    private var animationTimer: Timer?
    
    // Audio Engine & File
    // Use system default locale to match Siri language settings
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    
    // Permission states
    private var micPermissionGranted = false
    private var speechPermissionGranted = false
    
    // Data
    private var transcriptionText = ""
    
    // MARK: - ViewModels
    private let journalViewModel = JournalViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialState()
        setupWaveform()
        setupBackButton()
        setupAudioRouteChangeNotifications()
        printAudioDiagnostics()
        requestPermissions()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Audio Diagnostics
    private func printAudioDiagnostics() {
        print("[VoiceJournal] ========== AUDIO DIAGNOSTICS ==========")
        
        #if targetEnvironment(simulator)
        print("[VoiceJournal] Running on iOS SIMULATOR")
        print("[VoiceJournal] NOTE: Simulator uses Mac's microphone. Ensure:")
        print("[VoiceJournal]   1. Mac's System Preferences > Security & Privacy > Microphone allows Xcode/Simulator")
        print("[VoiceJournal]   2. Mac has a working audio input device selected")
        print("[VoiceJournal]   3. Try: System Preferences > Sound > Input - check if input level moves")
        #else
        print("[VoiceJournal] Running on PHYSICAL DEVICE")
        #endif
        
        let audioSession = AVAudioSession.sharedInstance()
        print("[VoiceJournal] Current category: \(audioSession.category.rawValue)")
        print("[VoiceJournal] Current mode: \(audioSession.mode.rawValue)")
        print("[VoiceJournal] Input available: \(audioSession.isInputAvailable)")
        print("[VoiceJournal] Sample rate: \(audioSession.sampleRate)")
        print("[VoiceJournal] Input channels: \(audioSession.inputNumberOfChannels)")
        
        if let inputs = audioSession.availableInputs {
            print("[VoiceJournal] Available audio inputs (\(inputs.count)):")
            for (index, input) in inputs.enumerated() {
                print("[VoiceJournal]   [\(index)] \(input.portName) (\(input.portType.rawValue))")
                if let dataSources = input.dataSources {
                    for ds in dataSources {
                        print("[VoiceJournal]       - \(ds.dataSourceName)")
                    }
                }
            }
        } else {
            print("[VoiceJournal] WARNING: No available audio inputs!")
        }
        
        if let currentInput = audioSession.currentRoute.inputs.first {
            print("[VoiceJournal] Current input: \(currentInput.portName) (\(currentInput.portType.rawValue))")
        } else {
            print("[VoiceJournal] WARNING: No current input route!")
        }
        
        print("[VoiceJournal] ================================================")
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
        
        print("[VoiceJournal] Audio route changed: \(reason.rawValue)")
        
        switch reason {
        case .newDeviceAvailable:
            print("[VoiceJournal] New audio device available")
            printAudioDiagnostics()
        case .oldDeviceUnavailable:
            print("[VoiceJournal] Audio device removed")
            if isRecording {
                print("[VoiceJournal] Stopping recording due to device removal")
                DispatchQueue.main.async {
                    self.stopRecording()
                    self.statusLabel.text = "Audio device disconnected"
                }
            }
        case .categoryChange:
            print("[VoiceJournal] Audio category changed")
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
            print("[VoiceJournal] Audio interruption BEGAN (e.g., phone call)")
            if isRecording {
                DispatchQueue.main.async {
                    self.stopRecording()
                    self.statusLabel.text = "Interrupted"
                }
            }
        case .ended:
            print("[VoiceJournal] Audio interruption ENDED")
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    print("[VoiceJournal] Audio session should resume")
                }
            }
        @unknown default:
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func setupBackButton() {
        GlassBackButton.add(to: self, action: #selector(backButtonTapped))
    }

    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    // setup
    private func setupInitialState() {
        titleLabel.text = "Say anything that's on your mind!"
        statusLabel.text = "Ready"
        
        [micButton, closeButton, checkButton].forEach {
            $0?.layer.cornerRadius = ($0?.frame.height ?? 0) / 2
            $0?.clipsToBounds = true
        }
        
        waveformStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for _ in 0..<18 {
            let bar = UIView()
            bar.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-400")?.withAlphaComponent(0.3) ?? UIColor.gray.withAlphaComponent(0.3)
            bar.layer.cornerRadius = 9
            bar.translatesAutoresizingMaskIntoConstraints = false
            
            bar.widthAnchor.constraint(equalToConstant: 18).isActive = true
            
            let heightConstraint = bar.heightAnchor.constraint(equalToConstant: 151)
            heightConstraint.isActive = true
            
            waveformStackView.addArrangedSubview(bar)
        }
    }
    
    private func setupWaveform() {
        waveformStackView.spacing = 3
        waveformStackView.distribution = .fill
        waveformStackView.alignment = .center
    }
    
    private func requestPermissions() {
        print("[VoiceJournal] Requesting permissions...")
        
        // Request Speech Recognition Permission
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            print("[VoiceJournal] Speech recognition authorization status: \(authStatus.rawValue)")
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("[VoiceJournal] Speech recognition AUTHORIZED")
                    self?.speechPermissionGranted = true
                    self?.updatePermissionStatus()
                case .denied:
                    print("[VoiceJournal] Speech recognition DENIED")
                    self?.speechPermissionGranted = false
                    self?.statusLabel.text = "Speech permission denied"
                    self?.micButton.isEnabled = false
                case .restricted:
                    print("[VoiceJournal] Speech recognition RESTRICTED")
                    self?.speechPermissionGranted = false
                    self?.statusLabel.text = "Speech recognition restricted"
                    self?.micButton.isEnabled = false
                case .notDetermined:
                    print("[VoiceJournal] Speech recognition NOT DETERMINED")
                    self?.speechPermissionGranted = false
                    self?.statusLabel.text = "Speech permission needed"
                    self?.micButton.isEnabled = false
                @unknown default:
                    print("[VoiceJournal] Speech recognition UNKNOWN status")
                    break
                }
            }
        }
        
        // Request Microphone Permission
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] allowed in
                print("[VoiceJournal] Microphone permission (iOS 17+): \(allowed ? "GRANTED" : "DENIED")")
                DispatchQueue.main.async {
                    self?.micPermissionGranted = allowed
                    if !allowed {
                        self?.statusLabel.text = "Mic permission needed"
                        self?.micButton.isEnabled = false
                    } else {
                        self?.updatePermissionStatus()
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
                print("[VoiceJournal] Microphone permission: \(allowed ? "GRANTED" : "DENIED")")
                DispatchQueue.main.async {
                    self?.micPermissionGranted = allowed
                    if !allowed {
                        self?.statusLabel.text = "Mic permission needed"
                        self?.micButton.isEnabled = false
                    } else {
                        self?.updatePermissionStatus()
                    }
                }
            }
        }
    }
    
    private func updatePermissionStatus() {
        if micPermissionGranted && speechPermissionGranted {
            print("[VoiceJournal] All permissions granted - Ready to record")
            statusLabel.text = "Ready"
            micButton.isEnabled = true
        }
    }
    
    private func verifyPermissionsBeforeRecording() -> Bool {
        print("[VoiceJournal] Verifying permissions before recording...")
        
        // Check Speech Recognition
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        print("[VoiceJournal] Speech recognition status: \(speechStatus.rawValue)")
        guard speechStatus == .authorized else {
            print("[VoiceJournal] ERROR: Speech recognition not authorized")
            statusLabel.text = "Speech permission required"
            return false
        }
        
        // Check Microphone
        var micGranted = false
        if #available(iOS 17.0, *) {
            let micStatus = AVAudioApplication.shared.recordPermission
            micGranted = (micStatus == .granted)
            print("[VoiceJournal] Microphone permission status (iOS 17+): \(micStatus)")
        } else {
            let micStatus = AVAudioSession.sharedInstance().recordPermission
            micGranted = (micStatus == .granted)
            print("[VoiceJournal] Microphone permission status: \(micStatus.rawValue)")
        }
        guard micGranted else {
            print("[VoiceJournal] ERROR: Microphone permission not granted")
            statusLabel.text = "Microphone permission required"
            return false
        }
        
        // Check SpeechRecognizer availability
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("[VoiceJournal] ERROR: Speech recognizer not available")
            statusLabel.text = "Speech recognition unavailable"
            return false
        }
        print("[VoiceJournal] Speech recognizer available: \(recognizer.isAvailable)")
        
        print("[VoiceJournal] All permissions verified - ready to record")
        return true
    }
    
     // MARK: - Actions
    @IBAction func micButtonTapped(_ sender: UIButton) {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        if isRecording {
            stopRecording()
        }
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func checkButtonTapped(_ sender: UIButton) {
        if isRecording {
            stopRecording()
        }
        saveJournalEntry()
    }
    
    // MARK: - Recording Logic
    private func startRecording() {
        print("[VoiceJournal] ========== START RECORDING ==========")
        
        // Verify permissions before starting
        guard verifyPermissionsBeforeRecording() else {
            print("[VoiceJournal] ERROR: Permissions not verified, aborting recording")
            return
        }
        
        // Stop any existing recording first
        if audioEngine.isRunning {
            print("[VoiceJournal] WARNING: Audio engine already running, stopping first")
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // Setup file path
        let fileName = "voice_journal_\(Int(Date().timeIntervalSince1970)).m4a"
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        recordingURL = paths[0].appendingPathComponent(fileName)
        print("[VoiceJournal] Recording URL: \(recordingURL?.path ?? "nil")")
        
        // Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        print("[VoiceJournal] Configuring audio session...")
        do {
            // Use playAndRecord with measurement mode for accurate speech recognition
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP])
            print("[VoiceJournal] Audio session category set: playAndRecord, mode: measurement")
            
            // CRITICAL: Activate the session BEFORE checking inputs
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("[VoiceJournal] Audio session ACTIVATED successfully")
            
            // Explicitly select the preferred input (important for Simulator)
            if let availableInputs = audioSession.availableInputs, !availableInputs.isEmpty {
                print("[VoiceJournal] Found \(availableInputs.count) available input(s)")
                
                // Prefer built-in microphone, fallback to first available
                let preferredInput = availableInputs.first { input in
                    input.portType == .builtInMic
                } ?? availableInputs.first
                
                if let input = preferredInput {
                    try audioSession.setPreferredInput(input)
                    print("[VoiceJournal] Preferred input set to: \(input.portName) (\(input.portType.rawValue))")
                }
            } else {
                print("[VoiceJournal] WARNING: No available inputs found!")
                #if targetEnvironment(simulator)
                print("[VoiceJournal] SIMULATOR: Check that your Mac's microphone is enabled and Xcode has microphone permission")
                print("[VoiceJournal] Go to: System Preferences > Security & Privacy > Privacy > Microphone")
                #endif
            }
            
            print("[VoiceJournal] Sample rate: \(audioSession.sampleRate)")
            print("[VoiceJournal] Input available: \(audioSession.isInputAvailable)")
            print("[VoiceJournal] Input channels: \(audioSession.inputNumberOfChannels)")
            
            // Log current route for debugging
            let currentRoute = audioSession.currentRoute
            print("[VoiceJournal] Current audio route inputs: \(currentRoute.inputs.map { $0.portName })")
            print("[VoiceJournal] Current audio route outputs: \(currentRoute.outputs.map { $0.portName })")
            
            if let inputDataSource = audioSession.inputDataSource {
                print("[VoiceJournal] Input data source: \(inputDataSource.dataSourceName)")
            }
            
            // Final validation that input is available
            guard audioSession.isInputAvailable else {
                print("[VoiceJournal] ERROR: No audio input available after activation!")
                statusLabel.text = "No microphone available"
                return
            }
        } catch {
            print("[VoiceJournal] ERROR: Audio Session setup failed: \(error.localizedDescription)")
            print("[VoiceJournal] Error details: \(error)")
            statusLabel.text = "Audio setup failed"
            return
        }
        
        // Cancel any previous recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Setup recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("[VoiceJournal] ERROR: Could not create recognition request")
            statusLabel.text = "Recognition setup failed"
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        print("[VoiceJournal] Recognition request created")
        
        // Setup Audio Engine Input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // CRITICAL: Validate recording format
        print("[VoiceJournal] Recording format: \(recordingFormat)")
        print("[VoiceJournal] Format sample rate: \(recordingFormat.sampleRate)")
        print("[VoiceJournal] Format channel count: \(recordingFormat.channelCount)")
        
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("[VoiceJournal] ERROR: Invalid recording format - sample rate or channels is 0")
            print("[VoiceJournal] Format details: \(recordingFormat.description)")
            print("[VoiceJournal] This typically means no audio input is available")
            
            #if targetEnvironment(simulator)
            print("[VoiceJournal] ==================== SIMULATOR TROUBLESHOOTING ====================")
            print("[VoiceJournal] The iOS Simulator uses your Mac's microphone.")
            print("[VoiceJournal] Please check the following:")
            print("[VoiceJournal]   1. System Preferences > Security & Privacy > Privacy > Microphone")
            print("[VoiceJournal]      - Ensure Xcode is listed and ENABLED")
            print("[VoiceJournal]   2. System Preferences > Sound > Input")
            print("[VoiceJournal]      - Select a working input device")
            print("[VoiceJournal]      - Check if input level indicator moves when you speak")
            print("[VoiceJournal]   3. Try restarting the Simulator")
            print("[VoiceJournal]   4. Try running on a physical device instead")
            print("[VoiceJournal] =================================================================")
            statusLabel.text = "Simulator: Check Mac microphone"
            #else
            statusLabel.text = "No audio input available"
            #endif
            
            // Try to show available inputs for debugging
            if let availableInputs = audioSession.availableInputs {
                print("[VoiceJournal] Available inputs: \(availableInputs.map { "\($0.portName) (\($0.portType.rawValue))" })")
            } else {
                print("[VoiceJournal] No available inputs detected")
            }
            
            // Log current route
            let currentRoute = audioSession.currentRoute
            print("[VoiceJournal] Current route inputs: \(currentRoute.inputs)")
            print("[VoiceJournal] Current route outputs: \(currentRoute.outputs)")
            
            return
        }
        
        // Setup Audio File for writing
        guard let recordingURL else {
            print("[VoiceJournal] ERROR: Missing recording URL")
            statusLabel.text = "File setup failed"
            return
        }

        do {
            audioFile = try AVAudioFile(forWriting: recordingURL, settings: recordingFormat.settings)
            print("[VoiceJournal] Audio file created successfully")
        } catch {
            print("[VoiceJournal] ERROR: Audio File setup failed: \(error.localizedDescription)")
            statusLabel.text = "File setup failed"
            return
        }

        // Remove existing tap and install new one
        inputNode.removeTap(onBus: 0)
        print("[VoiceJournal] Installing audio tap...")
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, time) in
            guard let self = self else { return }
            
            self.recognitionRequest?.append(buffer)

            do {
                try self.audioFile?.write(from: buffer)
            } catch {
                print("[VoiceJournal] ERROR: Writing to audio file: \(error.localizedDescription)")
            }
            
            // Update Waveform
            self.updateWaveform(buffer: buffer)
        }
        print("[VoiceJournal] Audio tap installed")
        
        // Start audio engine
        audioEngine.prepare()
        print("[VoiceJournal] Audio engine prepared")
        do {
            try audioEngine.start()
            print("[VoiceJournal] Audio engine STARTED successfully")
        } catch {
            print("[VoiceJournal] ERROR: Audio Engine start failed: \(error.localizedDescription)")
            statusLabel.text = "Audio engine failed to start"
            inputNode.removeTap(onBus: 0)
            return
        }
        
        // Start Recognition Task
        transcriptionText = "" 
        print("[VoiceJournal] Starting recognition task...")
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("[VoiceJournal] Recognition error: \(error.localizedDescription)")
            }
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                self.transcriptionText = text
                DispatchQueue.main.async {
                    self.titleLabel.text = text
                }
                print("[VoiceJournal] Transcription: \(text)")
            }
            
            if error != nil {
                print("[VoiceJournal] Recognition ended with error, stopping recording")
                DispatchQueue.main.async {
                    self.stopRecording()
                }
            }
        }
        
        if recognitionTask == nil {
            print("[VoiceJournal] WARNING: Recognition task is nil - speech recognizer may be unavailable")
        } else {
            print("[VoiceJournal] Recognition task started")
        }
        
        isRecording = true
        updateUI(for: .recording)
        print("[VoiceJournal] Recording started successfully")
    }
    
    private func stopRecording() {
        print("[VoiceJournal] ========== STOP RECORDING ==========")
        
        if !isRecording {
            print("[VoiceJournal] Not currently recording, ignoring stop request")
            return
        }
        
        print("[VoiceJournal] Stopping audio engine...")
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        print("[VoiceJournal] Audio engine stopped, tap removed")
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        print("[VoiceJournal] Recognition request ended, task cancelled")
        
        recognitionRequest = nil
        recognitionTask = nil
        audioFile = nil 
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("[VoiceJournal] Audio session deactivated")
        } catch {
            print("[VoiceJournal] WARNING: Could not deactivate audio session: \(error.localizedDescription)")
        }
        
        isRecording = false
        
        updateUI(for: .ready)
        print("[VoiceJournal] Recording stopped successfully")
    }
    
    private func saveJournalEntry() {
        guard let fileURL = recordingURL else {
            if transcriptionText.isEmpty { return }
            return 
        }
        
        statusLabel.text = "Saving..."
        checkButton.isEnabled = false
        
        // Create Journal
        let title = "Voice Entry"
        let transcript = transcriptionText.isEmpty ? "(No transcription)" : transcriptionText
        
        Task {
            do {
                let journal = try await journalViewModel.createJournal(
                    title: title,
                    content: transcript,
                    emotion: nil,
                    tags: nil,
                    mediaUrls: nil,
                    isFavorite: false,
                    entryType: "voice",
                    voiceRecordingUrl: nil,
                    transcriptionText: transcript,
                    feelings: nil,
                    activities: nil
                )
                await MainActor.run {
                    self.uploadAudio(journalId: journal.id.uuidString, fileUrl: fileURL)
                }
            } catch {
                await MainActor.run {
                    print("Error creating journal: \(error)")
                    self.statusLabel.text = "Error saving"
                    self.checkButton.isEnabled = true
                }
            }
        }
    }
    
    private func uploadAudio(journalId: String, fileUrl: URL) {
        statusLabel.text = "Uploading Audio..."
        Task {
            do {
                let data = try Data(contentsOf: fileUrl)
                let publicUrl = try await journalViewModel.uploadMedia(journalId: UUID(uuidString: journalId)!, fileData: data, fileName: fileUrl.lastPathComponent)
                try await journalViewModel.updateVoiceJournalMedia(
                    id: UUID(uuidString: journalId)!,
                    voiceRecordingUrl: publicUrl,
                    mediaUrls: [publicUrl]
                )
                await MainActor.run {
                    self.statusLabel.text = "Saved!"
                    let vc = MyJournalsListViewController(nibName: "MyJournalsListViewController", bundle: nil)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } catch {
                await MainActor.run {
                    print("Error uploading audio: \(error)")
                    self.statusLabel.text = "Upload failed"
                    self.checkButton.isEnabled = true
                }
            }
        }
    }
    
    enum VoiceState {
        case ready
        case recording
    }
    
    private func updateUI(for state: VoiceState) {
        UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: {
            switch state {
            case .ready:
                if self.transcriptionText.isEmpty {
                    self.titleLabel.text = "Say anything that's on your mind!"
                }
                self.statusLabel.text = "Ready"
                self.stopWaveformAnimation()
                self.micButton.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-400")?.withAlphaComponent(0.7)
                
            case .recording:
                self.statusLabel.text = "Listening..."
                self.micButton.backgroundColor = .systemRed.withAlphaComponent(0.7)
            }
        }, completion: nil)
    }
    
    // Waveform Animation
    private func updateWaveform(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let channelDataValue = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        
        let sum = channelDataValue.reduce(0) { $0 + $1 * $1 }
        let rms = sqrt(sum / Float(buffer.frameLength))
        
        var avgPower = 20 * log10(rms)

        if avgPower.isNaN || avgPower.isInfinite {
            avgPower = -160
        }
        
        DispatchQueue.main.async {
            self.animateWaveform(power: avgPower)
        }
    }

    private func animateWaveform(power: Float) {

        let minDb: Float = -60
        let clampedPower = max(minDb, min(0, power))
        let normalized = (clampedPower - minDb) / abs(minDb)
        
        UIView.animate(withDuration: 0.1) {
            for view in self.waveformStackView.arrangedSubviews {
                let randomFactor = CGFloat.random(in: 0.5...1.5)
                let height = CGFloat(normalized) * 150 * randomFactor
                let clamppedHeight = max(20, min(height, 150))
                
                if let constraint = view.constraints.first(where: { $0.firstAttribute == .height }) {
                    constraint.constant = clamppedHeight
                }
            }
            self.view.layoutIfNeeded()
        }
    }
    
    private func stopWaveformAnimation() {
        UIView.animate(withDuration: 0.3) {
            for view in self.waveformStackView.arrangedSubviews {
                if let constraint = view.constraints.first(where: { $0.firstAttribute == .height }) {
                    constraint.constant = 151
                }
            }
            self.view.layoutIfNeeded()
        }
    }
}
