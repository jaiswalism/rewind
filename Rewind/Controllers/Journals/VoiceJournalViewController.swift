import UIKit
import AVFoundation
import Speech

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
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    
    // Data
    private var transcriptionText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialState()
        setupWaveform()
        setupBackButton()
        requestPermissions()
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
            bar.backgroundColor = UIColor.white.withAlphaComponent(0.3)
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
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.statusLabel.text = "Ready"
                case .denied, .restricted, .notDetermined:
                    self.statusLabel.text = "Speech permission needed"
                    self.micButton.isEnabled = false
                @unknown default:
                    break
                }
            }
        }
        
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        self.statusLabel.text = "Mic permission needed"
                        self.micButton.isEnabled = false
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        self.statusLabel.text = "Mic permission needed"
                        self.micButton.isEnabled = false
                    }
                }
            }
        }
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
        // setup file path
        let fileName = "voice_journal_\(Int(Date().timeIntervalSince1970)).m4a"
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        recordingURL = paths[0].appendingPathComponent(fileName)
        
        // setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio Session error: \(error)")
            return
        }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        // Setup Audio Engine Input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Setup Audio File for writing
        do {
            audioFile = try AVAudioFile(forWriting: recordingURL!, settings: recordingFormat.settings)
        } catch {
            print("Audio File setup error: \(error)")
            return
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, time) in
            guard let self = self else { return }
            
            self.recognitionRequest?.append(buffer)

            do {
                try self.audioFile?.write(from: buffer)
            } catch {
                print("Error writing to audio file: \(error)")
            }
            
            // Update Waveform
            self.updateWaveform(buffer: buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio Engine start error: \(error)")
        }
        
        // Start Recognition Task
        transcriptionText = "" 
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                self.transcriptionText = text
                self.titleLabel.text = text
            }
            
            if error != nil {
                self.stopRecording() 
            }
        }
        
        isRecording = true
        updateUI(for: .recording)
    }
    
    private func stopRecording() {
        if !isRecording { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        audioFile = nil 
        
        isRecording = false
        
        updateUI(for: .ready)
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
        JournalService.shared.createJournal(
            title: title,
            content: transcriptionText.isEmpty ? "(No transcription)" : transcriptionText,
            type: .voice,
            transcription: transcriptionText
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let journal):
                    self?.uploadAudio(journalId: journal.id, fileUrl: fileURL)
                case .failure(let error):
                    print("Error creating journal: \(error)")
                    self?.statusLabel.text = "Error saving"
                    self?.checkButton.isEnabled = true
                }
            }
        }
    }
    
    private func uploadAudio(journalId: String, fileUrl: URL) {
        statusLabel.text = "Uploading Audio..."
        JournalService.shared.uploadMedia(journalId: journalId, fileUrl: fileUrl) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.statusLabel.text = "Saved!"
                    let vc = MyJournalsListViewController(nibName: "MyJournalsListViewController", bundle: nil)
                    self?.navigationController?.pushViewController(vc, animated: true)
                case .failure(let error):
                    print("Error uploading audio: \(error)")
                    self?.statusLabel.text = "Upload failed"
                    self?.checkButton.isEnabled = true
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
                self.micButton.backgroundColor = UIColor(named: "colors/Primary/Dark")?.withAlphaComponent(0.3)
                
            case .recording:
                self.statusLabel.text = "Listening..."
                self.micButton.backgroundColor = .red.withAlphaComponent(0.5)
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
