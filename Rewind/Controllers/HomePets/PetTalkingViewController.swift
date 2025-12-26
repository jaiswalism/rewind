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
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = UIColor(named: "colors/Primary/Light") ?? .white
        return button
    }()
    
    // MARK: - Properties
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
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
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Back Button
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}