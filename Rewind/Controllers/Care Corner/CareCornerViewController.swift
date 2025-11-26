//
//  CareCornerViewController.swift
//  Rewind
//
//  Created on 11/26/25.
//

import UIKit

class CareCornerViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Care Corner"
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let challengeHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Today's Challenge"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let challengeTextLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Put your phone face-down,\nfor 10 minutes. Test your\nwillpower."
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let tellCommunityButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Tell Community", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        button.layer.cornerRadius = 25
        return button
    }()
    
    private let activitiesHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Here's Some light activities"
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.65, alpha: 1.0)
        label.textAlignment = .center
        return label
    }()
    
    private let breathingCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0x7C/255.0, green: 0x7A/255.0, blue: 0xFF/255.0, alpha: 1.0)
        view.layer.cornerRadius = 24
        return view
    }()
    
    private let meditationCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0x7C/255.0, green: 0x7A/255.0, blue: 0xFF/255.0, alpha: 1.0)
        view.layer.cornerRadius = 24
        return view
    }()
    
    private let customTabBar = CustomTabBar()
    
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
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(challengeHeaderLabel)
        contentView.addSubview(challengeTextLabel)
        contentView.addSubview(tellCommunityButton)
        contentView.addSubview(activitiesHeaderLabel)
        contentView.addSubview(breathingCard)
        contentView.addSubview(meditationCard)
        
        setupCards()
        setupCustomTabBar()
        setupConstraints()
    }
    
    private func setupCards() {
        // Breathing Card
        let breathingLabel = UILabel()
        breathingLabel.translatesAutoresizingMaskIntoConstraints = false
        breathingLabel.text = "Breathing\nExercise"
        breathingLabel.font = UIFont.boldSystemFont(ofSize: 24)
        breathingLabel.textColor = .white
        breathingLabel.numberOfLines = 2
        breathingCard.addSubview(breathingLabel)
        
        // Meditation Card
        let meditationLabel = UILabel()
        meditationLabel.translatesAutoresizingMaskIntoConstraints = false
        meditationLabel.text = "Meditation"
        meditationLabel.font = UIFont.boldSystemFont(ofSize: 24)
        meditationLabel.textColor = .white
        meditationCard.addSubview(meditationLabel)
        
        NSLayoutConstraint.activate([
            breathingLabel.leadingAnchor.constraint(equalTo: breathingCard.leadingAnchor, constant: 24),
            breathingLabel.topAnchor.constraint(equalTo: breathingCard.topAnchor, constant: 24),
            
            meditationLabel.leadingAnchor.constraint(equalTo: meditationCard.leadingAnchor, constant: 24),
            meditationLabel.topAnchor.constraint(equalTo: meditationCard.topAnchor, constant: 24)
        ])
    }
    
    private func setupCustomTabBar() {
        customTabBar.parentViewController = self
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        customTabBar.selectTab(at: 3) // Select Care Corner tab
        view.addSubview(customTabBar)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: customTabBar.topAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Challenge Header
            challengeHeaderLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            challengeHeaderLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Challenge Text
            challengeTextLabel.topAnchor.constraint(equalTo: challengeHeaderLabel.bottomAnchor, constant: 8),
            challengeTextLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            challengeTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            // Tell Community Button
            tellCommunityButton.topAnchor.constraint(equalTo: challengeTextLabel.bottomAnchor, constant: 16),
            tellCommunityButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            tellCommunityButton.widthAnchor.constraint(equalToConstant: 180),
            tellCommunityButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Activities Header
            activitiesHeaderLabel.topAnchor.constraint(equalTo: tellCommunityButton.bottomAnchor, constant: 24),
            activitiesHeaderLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Breathing Card
            breathingCard.topAnchor.constraint(equalTo: activitiesHeaderLabel.bottomAnchor, constant: 16),
            breathingCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            breathingCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            breathingCard.heightAnchor.constraint(equalToConstant: 150),
            
            // Meditation Card
            meditationCard.topAnchor.constraint(equalTo: breathingCard.bottomAnchor, constant: 12),
            meditationCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            meditationCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            meditationCard.heightAnchor.constraint(equalToConstant: 150),
            meditationCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // Custom Tab Bar
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 10),
            customTabBar.heightAnchor.constraint(equalToConstant: 110)
        ])
    }
    
    private func setupActions() {
        tellCommunityButton.addTarget(self, action: #selector(tellCommunityTapped), for: .touchUpInside)
        
        let breathingTap = UITapGestureRecognizer(target: self, action: #selector(breathingTapped))
        breathingCard.addGestureRecognizer(breathingTap)
        
        let meditationTap = UITapGestureRecognizer(target: self, action: #selector(meditationTapped))
        meditationCard.addGestureRecognizer(meditationTap)
    }
    
    // MARK: - Actions
    @objc private func tellCommunityTapped() {
        print("Tell Community tapped")
        // Navigate to community or show share options
    }
    
    @objc private func breathingTapped() {
        let breathingVC = BreathingExerciseViewController()
        navigationController?.pushViewController(breathingVC, animated: true)
    }
    
    @objc private func meditationTapped() {
        let meditationVC = MeditationViewController()
        navigationController?.pushViewController(meditationVC, animated: true)
    }
}
