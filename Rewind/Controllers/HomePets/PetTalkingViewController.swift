//
//  PetTalkingViewController.swift
//  Rewind
//
//  Created on 12/26/25.
//

import UIKit

class PetTalkingViewController: UIViewController {
    
    // MARK: - UI Components
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = UIColor(named: "colors/Primary/Light") ?? .white
        button.backgroundColor = UIColor.clear
        button.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 16,
            bottom: 8,
            trailing: 16
        )
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
    
    // MARK: - Properties
    private var gradientLayer: CAGradientLayer?
    private var animationTimer: Timer?
    private var isAnimating = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("PetTalkingViewController loaded") // Debug log
        setupUI()
        setupActions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("PetTalkingViewController appeared") // Debug log
        print("Back button frame: \(backButton.frame)")
        print("Back button superview: \(backButton.superview != nil)")
        startBlobAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopBlobAnimation()
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
        
        view.addSubview(backButton)
        view.addSubview(animatedBlobContainer)
        
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
            
            // Animated Blob Container
            animatedBlobContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animatedBlobContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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
            centerDot.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
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
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        print("Back button tapped") // Debug log
        
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
            navController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
