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
    
    // MARK: Top Background Circle
    private let topIllustration: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        // Use the asset name provided by the user
        imageView.image = UIImage(named: "illustrations/careCorner/topSectionBG")
        return imageView
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
        button.backgroundColor = UIColor(named: "colors/Primary/Darker")?.withAlphaComponent(0.6) ?? UIColor.white.withAlphaComponent(0.25)
        button.layer.cornerRadius = 25
        return button
    }()
    
    private let activitiesHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Here's Some light activities"
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = UIColor(named: "colors/Primary/Dark") ?? UIColor(red: 0.45, green: 0.45, blue: 0.65, alpha: 1.0)
        label.textAlignment = .center
        return label
    }()
    
    private let breathingCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-300")
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        return view
    }()
    
    private let meditationCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-300")
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        return view
    }()

    // MARK: Card Illustrations
    private let breathingIllustration: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "illustrations/careCorner/breathingBtnBg")
        return imageView
    }()

    private let meditationIllustration: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "illustrations/careCorner/meditationBtnBg")
        return imageView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // setting the main background color

        view.backgroundColor = UIColor(named: "colors/Primary/Light :active") ?? .systemBlue
        
        // putting the illustration first

        view.addSubview(topIllustration)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // layering content on top

        contentView.addSubview(titleLabel)
        contentView.addSubview(challengeHeaderLabel)
        contentView.addSubview(challengeTextLabel)
        contentView.addSubview(tellCommunityButton)
        contentView.addSubview(activitiesHeaderLabel)
        contentView.addSubview(breathingCard)
        contentView.addSubview(meditationCard)
        
        setupCards()
        setupConstraints()
    }
    
    private func setupCards() {
        // 1. putting illustrations on the cards

        breathingCard.addSubview(breathingIllustration)
        meditationCard.addSubview(meditationIllustration)

        // Constraints to make illustrations cover the entire card area
        NSLayoutConstraint.activate([
            breathingIllustration.topAnchor.constraint(equalTo: breathingCard.topAnchor),
            breathingIllustration.leadingAnchor.constraint(equalTo: breathingCard.leadingAnchor),
            breathingIllustration.trailingAnchor.constraint(equalTo: breathingCard.trailingAnchor),
            breathingIllustration.bottomAnchor.constraint(equalTo: breathingCard.bottomAnchor),

            meditationIllustration.topAnchor.constraint(equalTo: meditationCard.topAnchor),
            meditationIllustration.leadingAnchor.constraint(equalTo: meditationCard.leadingAnchor),
            meditationIllustration.trailingAnchor.constraint(equalTo: meditationCard.trailingAnchor),
            meditationIllustration.bottomAnchor.constraint(equalTo: meditationCard.bottomAnchor),
        ])
        
        // 2. putting text on top

        
        // Breathing Card Label
        let breathingLabel = UILabel()
        breathingLabel.translatesAutoresizingMaskIntoConstraints = false
        breathingLabel.text = "Breathing\nExercise"
        breathingLabel.font = UIFont.boldSystemFont(ofSize: 24)
        breathingLabel.textColor = .white
        breathingLabel.numberOfLines = 2
        breathingCard.addSubview(breathingLabel)
        
        // Meditation Card Label
        let meditationLabel = UILabel()
        meditationLabel.translatesAutoresizingMaskIntoConstraints = false
        meditationLabel.text = "Meditation"
        meditationLabel.font = UIFont.boldSystemFont(ofSize: 24)
        meditationLabel.textColor = .white
        meditationCard.addSubview(meditationLabel)
        
        NSLayoutConstraint.activate([
            // Card Label Constraints
            breathingLabel.leadingAnchor.constraint(equalTo: breathingCard.leadingAnchor, constant: 24),
            breathingLabel.topAnchor.constraint(equalTo: breathingCard.topAnchor, constant: 24),
            
            meditationLabel.leadingAnchor.constraint(equalTo: meditationCard.leadingAnchor, constant: 24),
            meditationLabel.topAnchor.constraint(equalTo: meditationCard.topAnchor, constant: 24)
        ])
    }
    
    
    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            // NEW: pinning the top illustration

            topIllustration.topAnchor.constraint(equalTo: view.topAnchor),
            topIllustration.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topIllustration.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // fixed height for the curve

            topIllustration.heightAnchor.constraint(equalToConstant: 380),

            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // content view defines the scrollable area

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 4),
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
            
            // Activities Header (Starts below the illustration to avoid overlap)
            activitiesHeaderLabel.topAnchor.constraint(equalTo: topIllustration.bottomAnchor, constant: 24),
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
            meditationCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupActions() {
        tellCommunityButton.addTarget(self, action: #selector(tellCommunityTapped), for: .touchUpInside)
        
        let breathingTap = UITapGestureRecognizer(target: self, action: #selector(breathingTapped))
        breathingCard.addGestureRecognizer(breathingTap)
        
        let meditationTap = UITapGestureRecognizer(target: self, action: #selector(meditationTapped))
        meditationCard.addGestureRecognizer(meditationTap)
    }
    
    // navigation

    @objc private func tellCommunityTapped() {
        let createPostVC = CreatePostViewController()
        navigationController?.pushViewController(createPostVC, animated: true)
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
