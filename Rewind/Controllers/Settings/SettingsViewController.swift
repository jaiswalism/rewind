//
//  SettingsViewController.swift
//  Rewind
//
//  Created on 11/26/25.
//

import UIKit

class SettingsViewController: UIViewController {
    
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
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Settings"
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textColor = .white
        return label
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 60
        imageView.layer.borderWidth = 4
        imageView.layer.borderColor = UIColor.white.cgColor
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Aviral Sharma"
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "diaryofmind@gmail.com"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Chennai, Tamil Nadu"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let generalSettingsHeaderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let generalSettingsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "General Settings"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = .white
        return label
    }()
    
    private let generalSettingsIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "face.smiling")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let personalInfoButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let inviteFriendsButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let submitFeedbackButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let logOutHeaderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let logOutHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Log Out"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = .white
        return label
    }()
    
    private let logOutHeaderIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "face.smiling")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let logOutButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
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
        
        // Add all subviews
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(emailLabel)
        contentView.addSubview(locationLabel)
        contentView.addSubview(generalSettingsHeaderView)
        generalSettingsHeaderView.addSubview(generalSettingsLabel)
        generalSettingsHeaderView.addSubview(generalSettingsIcon)
        contentView.addSubview(personalInfoButton)
        contentView.addSubview(inviteFriendsButton)
        contentView.addSubview(submitFeedbackButton)
        contentView.addSubview(logOutHeaderView)
        logOutHeaderView.addSubview(logOutHeaderLabel)
        logOutHeaderView.addSubview(logOutHeaderIcon)
        contentView.addSubview(logOutButton)
        
        setupConstraints()
        configureButtons()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Back Button
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Title Label
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Profile Image
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // Name Label
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Email Label
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            emailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Location Label
            locationLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 4),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // General Settings Header
            generalSettingsHeaderView.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 40),
            generalSettingsHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            generalSettingsHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            generalSettingsHeaderView.heightAnchor.constraint(equalToConstant: 30),
            
            generalSettingsLabel.leadingAnchor.constraint(equalTo: generalSettingsHeaderView.leadingAnchor, constant: 16),
            generalSettingsLabel.centerYAnchor.constraint(equalTo: generalSettingsHeaderView.centerYAnchor),
            
            generalSettingsIcon.trailingAnchor.constraint(equalTo: generalSettingsHeaderView.trailingAnchor, constant: -16),
            generalSettingsIcon.centerYAnchor.constraint(equalTo: generalSettingsHeaderView.centerYAnchor),
            generalSettingsIcon.widthAnchor.constraint(equalToConstant: 24),
            generalSettingsIcon.heightAnchor.constraint(equalToConstant: 24),
            
            // Personal Info Button
            personalInfoButton.topAnchor.constraint(equalTo: generalSettingsHeaderView.bottomAnchor, constant: 16),
            personalInfoButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            personalInfoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            personalInfoButton.heightAnchor.constraint(equalToConstant: 70),
            
            // Invite Friends Button
            inviteFriendsButton.topAnchor.constraint(equalTo: personalInfoButton.bottomAnchor, constant: 16),
            inviteFriendsButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            inviteFriendsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            inviteFriendsButton.heightAnchor.constraint(equalToConstant: 70),
            
            // Submit Feedback Button
            submitFeedbackButton.topAnchor.constraint(equalTo: inviteFriendsButton.bottomAnchor, constant: 16),
            submitFeedbackButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            submitFeedbackButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            submitFeedbackButton.heightAnchor.constraint(equalToConstant: 70),
            
            // Log Out Header
            logOutHeaderView.topAnchor.constraint(equalTo: submitFeedbackButton.bottomAnchor, constant: 40),
            logOutHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            logOutHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            logOutHeaderView.heightAnchor.constraint(equalToConstant: 30),
            
            logOutHeaderLabel.leadingAnchor.constraint(equalTo: logOutHeaderView.leadingAnchor, constant: 16),
            logOutHeaderLabel.centerYAnchor.constraint(equalTo: logOutHeaderView.centerYAnchor),
            
            logOutHeaderIcon.trailingAnchor.constraint(equalTo: logOutHeaderView.trailingAnchor, constant: -16),
            logOutHeaderIcon.centerYAnchor.constraint(equalTo: logOutHeaderView.centerYAnchor),
            logOutHeaderIcon.widthAnchor.constraint(equalToConstant: 24),
            logOutHeaderIcon.heightAnchor.constraint(equalToConstant: 24),
            
            // Log Out Button
            logOutButton.topAnchor.constraint(equalTo: logOutHeaderView.bottomAnchor, constant: 16),
            logOutButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            logOutButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            logOutButton.heightAnchor.constraint(equalToConstant: 70),
            logOutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func configureButtons() {
        configureSettingButton(
            personalInfoButton,
            icon: "person.fill",
            title: "Personal Information"
        )
        
        configureSettingButton(
            inviteFriendsButton,
            icon: "square.and.arrow.up",
            title: "Invite Friends"
        )
        
        configureSettingButton(
            submitFeedbackButton,
            icon: "message.fill",
            title: "Submit Feedback"
        )
        
        configureSettingButton(
            logOutButton,
            icon: "rectangle.portrait.and.arrow.right",
            title: "Log Out"
        )
    }
    
    private func configureSettingButton(_ button: UIButton, icon: String, title: String) {
        button.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        button.layer.cornerRadius = 20
        
        // Icon container
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        iconContainer.layer.cornerRadius = 16
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        
        iconContainer.addSubview(iconImageView)
        button.addSubview(iconContainer)
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .white
        button.addSubview(titleLabel)
        
        // Chevron
        let chevronImageView = UIImageView()
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .white
        chevronImageView.contentMode = .scaleAspectFit
        button.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 48),
            iconContainer.heightAnchor.constraint(equalToConstant: 48),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            
            chevronImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 20),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        personalInfoButton.addTarget(self, action: #selector(personalInfoTapped), for: .touchUpInside)
        inviteFriendsButton.addTarget(self, action: #selector(inviteFriendsTapped), for: .touchUpInside)
        submitFeedbackButton.addTarget(self, action: #selector(submitFeedbackTapped), for: .touchUpInside)
        logOutButton.addTarget(self, action: #selector(logOutTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func personalInfoTapped() {
        print("Personal Information tapped")
        // Navigate to personal info screen
    }
    
    @objc private func inviteFriendsTapped() {
        print("Invite Friends tapped")
        // Show invite friends functionality
    }
    
    @objc private func submitFeedbackTapped() {
        print("Submit Feedback tapped")
        // Navigate to feedback screen
    }
    
    @objc private func logOutTapped() {
        print("Log Out tapped")
        // Show logout confirmation
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
            // Perform logout
        })
        present(alert, animated: true)
    }
}
