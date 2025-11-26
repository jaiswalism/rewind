//
//  VoiceJournalViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

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
    
    // Dummy text to simulate transcription appearing
    private let transcriptionText = "Today I had a hard time concentrating. I was very worried about making mistakes and was .."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialState()
        setupWaveform()
    }
    
    // MARK: - Setup
    private func setupInitialState() {
        titleLabel.text = "Say anything that's on your mind!"
        statusLabel.text = "Ready"
        
        // Style the buttons
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
    
    // MARK: - Actions
    @IBAction func micButtonTapped(_ sender: UIButton) {
        isRecording.toggle()
        updateUI(for: isRecording ? .recording : .ready)
    }
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        // Handle close/cancel logic
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func checkButtonTapped(_ sender: UIButton) {
        // Handle save/finish logic
        let vc = MyJournalsListViewController(nibName: "MyJournalsListViewController", bundle: nil)
            navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - State Management
    
    enum VoiceState {
        case ready
        case recording
    }
    
    private func updateUI(for state: VoiceState) {
        UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: {
            switch state {
            case .ready:
                self.titleLabel.text = "Say anything that's on your mind!"
                self.statusLabel.text = "Ready"
                self.stopWaveformAnimation()
                
            case .recording:
                self.titleLabel.text = self.transcriptionText // Simulate transcription
                self.statusLabel.text = "Speak..."
                self.startWaveformAnimation()
            }
        }, completion: nil)
    }
    
    // MARK: - Waveform Animation (Simulated)
    
    private func startWaveformAnimation() {
        // Invalidate existing timer if any
        animationTimer?.invalidate()
        
        // Timer to randomize bar heights rapidly
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.1) {
                for view in self.waveformStackView.arrangedSubviews {
                    let randomHeight = CGFloat.random(in: 20...151)
                    
                    if let constraint = view.constraints.first(where: { $0.firstAttribute == .height }) {
                        constraint.constant = randomHeight
                    }
                    
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func stopWaveformAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        
        UIView.animate(withDuration: 0.3) {
            for view in self.waveformStackView.arrangedSubviews {
                // Reset to static height
                if let constraint = view.constraints.first(where: { $0.firstAttribute == .height }) {
                    constraint.constant = 151
                }
                
            }
            self.view.layoutIfNeeded()
        }
    }
}
