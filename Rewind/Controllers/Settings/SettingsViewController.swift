//
//  SettingsViewController.swift
//  Rewind
//
//  Created on 11/26/25.
//

import UIKit
import Supabase

class SettingsViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = .white
        return b
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Settings"
        l.font = UIFont.boldSystemFont(ofSize: 28)
        l.textColor = .white
        return l
    }()
    
    // Profile avatar with animated ring
    private let avatarRingView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 66
        v.layer.borderWidth = 3
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        return v
    }()
    
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        iv.layer.cornerRadius = 60
        iv.layer.borderWidth = 3
        iv.layer.borderColor = UIColor.white.cgColor
        iv.image = UIImage(systemName: "person.crop.circle.fill")
        iv.tintColor = UIColor.white.withAlphaComponent(0.5)
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = ""
        l.font = UIFont.boldSystemFont(ofSize: 24)
        l.textColor = .white
        l.textAlignment = .center
        l.alpha = 0
        return l
    }()
    
    private let emailLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = ""
        l.font = UIFont.systemFont(ofSize: 16)
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        l.textAlignment = .center
        l.alpha = 0
        return l
    }()
    
    private let locationLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = ""
        l.font = UIFont.systemFont(ofSize: 16)
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        l.textAlignment = .center
        l.alpha = 0
        return l
    }()
    
    // Stats strip
    private let statsCard: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.13)
        v.layer.cornerRadius = 20
        v.alpha = 0
        return v
    }()
    
    private let generalSettingsHeaderView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.alpha = 0
        return v
    }()
    
    private let generalSettingsLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "General Settings"
        l.font = UIFont.boldSystemFont(ofSize: 18)
        l.textColor = UIColor.white.withAlphaComponent(0.7)
        return l
    }()
    
    private let personalInfoButton: UIButton = {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.alpha = 0
        b.transform = CGAffineTransform(translationX: 0, y: 30)
        return b
    }()
    
    private let inviteFriendsButton: UIButton = {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.alpha = 0
        b.transform = CGAffineTransform(translationX: 0, y: 30)
        return b
    }()
    
    private let submitFeedbackButton: UIButton = {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.alpha = 0
        b.transform = CGAffineTransform(translationX: 0, y: 30)
        return b
    }()
    
    private let logOutHeaderView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.alpha = 0
        return v
    }()
    
    private let logOutHeaderLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Account"
        l.font = UIFont.boldSystemFont(ofSize: 18)
        l.textColor = UIColor.white.withAlphaComponent(0.7)
        return l
    }()
    
    private let logOutButton: UIButton = {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.alpha = 0
        b.transform = CGAffineTransform(translationX: 0, y: 30)
        return b
    }()
    
    // MARK: - Properties
    private let userViewModel = UserViewModel()
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchProfile()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runEntranceAnimations()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Gradient background
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor(red: 0.28, green: 0.35, blue: 0.88, alpha: 1.0).cgColor,
            UIColor(red: 0.48, green: 0.33, blue: 0.95, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        contentView.addSubview(avatarRingView)
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(emailLabel)
        contentView.addSubview(locationLabel)
        contentView.addSubview(statsCard)
        buildStatsCard()
        contentView.addSubview(generalSettingsHeaderView)
        generalSettingsHeaderView.addSubview(generalSettingsLabel)
        generalSettingsLabel.letterSpacing(1.2)
        contentView.addSubview(personalInfoButton)
        contentView.addSubview(inviteFriendsButton)
        contentView.addSubview(submitFeedbackButton)
        contentView.addSubview(logOutHeaderView)
        logOutHeaderView.addSubview(logOutHeaderLabel)
        contentView.addSubview(logOutButton)
        
        setupConstraints()
        configureButtons()
    }
    
    private func buildStatsCard() {
        let items: [(String, String)] = [
            ("42", "Journal"),
            ("128", "Likes"),
            ("15", "Streak")
        ]
        
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill   // NOT fillEqually — dividers must stay thin
        stack.alignment = .center
        statsCard.addSubview(stack)
        
        var columns: [UIView] = []
        
        for (i, item) in items.enumerated() {
            let col = UIStackView()
            col.axis = .vertical
            col.alignment = .center
            col.spacing = 4
            
            let num = UILabel()
            num.text = item.0
            num.font = UIFont.boldSystemFont(ofSize: 22)
            num.textColor = .white
            
            let name = UILabel()
            name.text = item.1
            name.font = UIFont.systemFont(ofSize: 13)
            name.textColor = UIColor.white.withAlphaComponent(0.65)
            
            col.addArrangedSubview(num)
            col.addArrangedSubview(name)
            stack.addArrangedSubview(col)
            columns.append(col)
            
            // Thin divider — NOT fillEqually so this must have a fixed width
            if i < items.count - 1 {
                let div = UIView()
                div.translatesAutoresizingMaskIntoConstraints = false
                div.backgroundColor = UIColor.white.withAlphaComponent(0.25)
                div.widthAnchor.constraint(equalToConstant: 1).isActive = true
                div.heightAnchor.constraint(equalToConstant: 36).isActive = true
                // Resist being stretched
                div.setContentHuggingPriority(.required, for: .horizontal)
                div.setContentCompressionResistancePriority(.required, for: .horizontal)
                stack.addArrangedSubview(div)
            }
        }
        
        // Make all columns equal width
        for i in 1 ..< columns.count {
            columns[i].widthAnchor.constraint(equalTo: columns[0].widthAnchor).isActive = true
        }
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Ring behind avatar
            avatarRingView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            avatarRingView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarRingView.widthAnchor.constraint(equalToConstant: 132),
            avatarRingView.heightAnchor.constraint(equalToConstant: 132),
            
            profileImageView.centerXAnchor.constraint(equalTo: avatarRingView.centerXAnchor),
            profileImageView.centerYAnchor.constraint(equalTo: avatarRingView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            nameLabel.topAnchor.constraint(equalTo: avatarRingView.bottomAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            emailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            locationLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 4),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            statsCard.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 24),
            statsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statsCard.heightAnchor.constraint(equalToConstant: 72),
            
            generalSettingsHeaderView.topAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: 36),
            generalSettingsHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            generalSettingsHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            generalSettingsHeaderView.heightAnchor.constraint(equalToConstant: 28),
            
            generalSettingsLabel.leadingAnchor.constraint(equalTo: generalSettingsHeaderView.leadingAnchor, constant: 4),
            generalSettingsLabel.centerYAnchor.constraint(equalTo: generalSettingsHeaderView.centerYAnchor),
            
            personalInfoButton.topAnchor.constraint(equalTo: generalSettingsHeaderView.bottomAnchor, constant: 12),
            personalInfoButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            personalInfoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            personalInfoButton.heightAnchor.constraint(equalToConstant: 70),
            
            inviteFriendsButton.topAnchor.constraint(equalTo: personalInfoButton.bottomAnchor, constant: 12),
            inviteFriendsButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            inviteFriendsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            inviteFriendsButton.heightAnchor.constraint(equalToConstant: 70),
            
            submitFeedbackButton.topAnchor.constraint(equalTo: inviteFriendsButton.bottomAnchor, constant: 12),
            submitFeedbackButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            submitFeedbackButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            submitFeedbackButton.heightAnchor.constraint(equalToConstant: 70),
            
            logOutHeaderView.topAnchor.constraint(equalTo: submitFeedbackButton.bottomAnchor, constant: 36),
            logOutHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            logOutHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            logOutHeaderView.heightAnchor.constraint(equalToConstant: 28),
            
            logOutHeaderLabel.leadingAnchor.constraint(equalTo: logOutHeaderView.leadingAnchor, constant: 4),
            logOutHeaderLabel.centerYAnchor.constraint(equalTo: logOutHeaderView.centerYAnchor),
            
            logOutButton.topAnchor.constraint(equalTo: logOutHeaderView.bottomAnchor, constant: 12),
            logOutButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            logOutButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            logOutButton.heightAnchor.constraint(equalToConstant: 70),
            logOutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50)
        ])
    }
    
    private func configureButtons() {
        configureSettingButton(personalInfoButton, icon: "person.fill", title: "Personal Information")
        configureSettingButton(inviteFriendsButton, icon: "square.and.arrow.up", title: "Invite Friends")
        configureSettingButton(submitFeedbackButton, icon: "message.fill", title: "Submit Feedback")
        configureLogOutButton(logOutButton)
    }
    
    private func configureSettingButton(_ button: UIButton, icon: String, title: String) {
        button.backgroundColor = UIColor.white.withAlphaComponent(0.13)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        iconContainer.layer.cornerRadius = 14
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconImageView)
        button.addSubview(iconContainer)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .white
        button.addSubview(titleLabel)
        
        let chevronImageView = UIImageView()
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = UIColor.white.withAlphaComponent(0.5)
        chevronImageView.contentMode = .scaleAspectFit
        button.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            
            chevronImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 18),
            chevronImageView.heightAnchor.constraint(equalToConstant: 18)
        ])
        
        // Press animation via touchDown/touchUp
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: [.touchDown, .touchDragEnter])
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
    }
    
    private func configureLogOutButton(_ button: UIButton) {
        button.backgroundColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.18)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 0.3).cgColor
        
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 0.25)
        iconContainer.layer.cornerRadius = 14
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: "rectangle.portrait.and.arrow.right")
        iconImageView.tintColor = UIColor(red: 1, green: 0.55, blue: 0.55, alpha: 1)
        iconImageView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconImageView)
        button.addSubview(iconContainer)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Log Out"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = UIColor(red: 1, green: 0.55, blue: 0.55, alpha: 1)
        button.addSubview(titleLabel)
        
        let chevronImageView = UIImageView()
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = UIColor(red: 1, green: 0.55, blue: 0.55, alpha: 0.5)
        chevronImageView.contentMode = .scaleAspectFit
        button.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            
            chevronImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 18),
            chevronImageView.heightAnchor.constraint(equalToConstant: 18)
        ])
        
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: [.touchDown, .touchDragEnter])
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        personalInfoButton.addTarget(self, action: #selector(personalInfoTapped), for: .touchUpInside)
        inviteFriendsButton.addTarget(self, action: #selector(inviteFriendsTapped), for: .touchUpInside)
        submitFeedbackButton.addTarget(self, action: #selector(submitFeedbackTapped), for: .touchUpInside)
        logOutButton.addTarget(self, action: #selector(logOutTapped), for: .touchUpInside)
    }
    
    // MARK: - Data Fetching

    private func fetchProfile() {
        Task {
            await userViewModel.fetchProfile()
            await MainActor.run {
                if let user = userViewModel.user {
                    populateUI(with: user)
                }
            }
        }
    }

    private func populateUI(with user: DBUser) {
        UIView.transition(with: nameLabel, duration: 0.3, options: .transitionCrossDissolve) {
            self.nameLabel.text = user.name
        }
        UIView.transition(with: emailLabel, duration: 0.3, options: .transitionCrossDissolve) {
            self.emailLabel.text = user.email ?? ""
        }
        UIView.transition(with: locationLabel, duration: 0.3, options: .transitionCrossDissolve) {
            self.locationLabel.text = user.location ?? ""
        }
        if let url = user.profileImageUrl {
            loadProfileImage(from: url)
        }
    }

    private func loadProfileImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        Task {
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let image = UIImage(data: data) {
                await MainActor.run {
                    UIView.transition(with: self.profileImageView, duration: 0.35, options: .transitionCrossDissolve) {
                        self.profileImageView.image = image
                        self.profileImageView.tintColor = .clear
                    }
                }
            }
        }
    }

    // MARK: - Entrance Animations

    private func runEntranceAnimations() {
        // Avatar drops in with spring
        avatarRingView.alpha = 0
        avatarRingView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        profileImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 0.65, delay: 0.05, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5) {
            self.avatarRingView.alpha = 1
            self.avatarRingView.transform = .identity
            self.profileImageView.transform = .identity
        }
        
        // Name / email / location fade+slide up staggered
        let infoViews: [(UIView, TimeInterval)] = [
            (nameLabel, 0.18),
            (emailLabel, 0.26),
            (locationLabel, 0.34)
        ]
        for (view, delay) in infoViews {
            view.transform = CGAffineTransform(translationX: 0, y: 20)
            UIView.animate(withDuration: 0.5, delay: delay, usingSpringWithDamping: 0.75, initialSpringVelocity: 0) {
                view.alpha = 1
                view.transform = .identity
            }
        }
        
        // Stats card slides up
        statsCard.transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(withDuration: 0.5, delay: 0.42, usingSpringWithDamping: 0.75, initialSpringVelocity: 0) {
            self.statsCard.alpha = 1
            self.statsCard.transform = .identity
        }
        
        // Section headers fade
        UIView.animate(withDuration: 0.4, delay: 0.52) {
            self.generalSettingsHeaderView.alpha = 1
            self.logOutHeaderView.alpha = 1
        }
        
        // Buttons stagger in from below
        let buttons: [(UIView, TimeInterval)] = [
            (personalInfoButton, 0.58),
            (inviteFriendsButton, 0.67),
            (submitFeedbackButton, 0.76),
            (logOutButton, 0.88)
        ]
        for (btn, delay) in buttons {
            UIView.animate(withDuration: 0.5, delay: delay, usingSpringWithDamping: 0.78, initialSpringVelocity: 0) {
                btn.alpha = 1
                btn.transform = .identity
            }
        }
    }
    

    // MARK: - Button Press Animations
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.allowUserInteraction, .curveEaseInOut]) {
            sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            sender.alpha = 0.85
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.4, options: .allowUserInteraction) {
            sender.transform = .identity
            sender.alpha = 1.0
        }
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        if let nav = navigationController {
            if let index = nav.viewControllers.firstIndex(of: self), index > 0 {
                nav.popViewController(animated: true)
                return
            }
        }
        if presentingViewController != nil {
            dismiss(animated: true)
            return
        }
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func personalInfoTapped() {
        let personalInfoVC = PersonalInformationViewController()
        navigationController?.pushViewController(personalInfoVC, animated: true)
    }
    
    @objc private func inviteFriendsTapped() { }
    
    @objc private func submitFeedbackTapped() { }
    
    @objc private func logOutTapped() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
            Task {
                do {
                    try await SupabaseConfig.shared.client.auth.signOut()
                    await MainActor.run {
                        let loginVC = LoginViewController()
                        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                            sceneDelegate.setRoot(loginVC)
                        } else {
                            loginVC.modalPresentationStyle = .fullScreen
                            self?.present(loginVC, animated: true, completion: nil)
                        }
                    }
                } catch {
                    await MainActor.run {
                        let errorAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(errorAlert, animated: true)
                    }
                }
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - UILabel helper
private extension UILabel {
    func letterSpacing(_ spacing: CGFloat) {
        if let text = self.text {
            let attrs = NSAttributedString(string: text, attributes: [.kern: spacing, .font: self.font as Any, .foregroundColor: self.textColor as Any])
            self.attributedText = attrs
        }
    }
}
