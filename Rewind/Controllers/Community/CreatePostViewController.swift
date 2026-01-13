//
//  CreatePostViewController.swift
//  Rewind
//
//  Created by Shyam on 07/11/25.
//

import UIKit

class CreatePostViewController: UIViewController {

    // MARK: - UI Components
    
    // Gradient Background
    private let gradientLayer = CAGradientLayer()
    
    // Header
    private let headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        
        // Glass effect container
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        button.clipsToBounds = true
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let headerTitle: UILabel = {
        let label = UILabel()
        label.text = "Create Post"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let postButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Post", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.tintColor = UIColor(named: "colors/Blue&Shades/blue-500")
        button.backgroundColor = .white
        button.layer.cornerRadius = 18
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Scroll View for content
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 20, left: 24, bottom: 40, right: 24)
        return stack
    }()
    
    // Profile Section
    private let profileContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "illustrations/homePets/profile")
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 24
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Shyam" // Placeholder
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let privacyLabel: UILabel = {
        let label = UILabel()
        label.text = "Public Post"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Text Input
    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 18, weight: .regular)
        tv.textColor = .white
        tv.backgroundColor = .clear
        tv.isScrollEnabled = false
        tv.tintColor = .white
        tv.delegate = self
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "What's on your mind? Share your thoughts..."
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Tags Section
    private let tagsLabel: UILabel = {
        let label = UILabel()
        label.text = "Add a Tag"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tagsScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let tagsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let availableTags = ["STRESS", "ANXIETY", "HAPPINESS", "GRATITUDE", "WORK", "RELATIONSHIPS", "HEALTH"]
    private var selectedTagButton: UIButton?
    
    // Anonymous Toggle
    private let anonymousContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let anonymousIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "eye.slash.fill"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let anonymousLabel: UILabel = {
        let label = UILabel()
        label.text = "Post Anonymously"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let anonymousSwitch: UISwitch = {
        let s = UISwitch()
        s.onTintColor = UIColor(named: "colors/Blue&Shades/blue-500") // Or a contrasting color
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Gradient
        let startColor = UIColor(named: "colors/Blue&Shades/blue-400")?.cgColor ?? UIColor.systemBlue.cgColor
        let endColor = UIColor(named: "colors/Blue&Shades/blue-600")?.cgColor ?? UIColor.blue.cgColor
        gradientLayer.colors = [startColor, endColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.addSublayer(gradientLayer)
        
        // Header
        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(headerTitle)
        headerView.addSubview(postButton)
        
        // Content
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        // Assemble Profile
        profileContainer.addSubview(avatarImageView)
        
        let nameStack = UIStackView(arrangedSubviews: [nameLabel, privacyLabel])
        nameStack.axis = .vertical
        nameStack.spacing = 2
        nameStack.translatesAutoresizingMaskIntoConstraints = false
        profileContainer.addSubview(nameStack)
        
        NSLayoutConstraint.activate([
            profileContainer.heightAnchor.constraint(equalToConstant: 50),
            
            avatarImageView.leadingAnchor.constraint(equalTo: profileContainer.leadingAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: profileContainer.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 48),
            avatarImageView.heightAnchor.constraint(equalToConstant: 48),
            
            nameStack.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameStack.centerYAnchor.constraint(equalTo: profileContainer.centerYAnchor),
            nameStack.trailingAnchor.constraint(equalTo: profileContainer.trailingAnchor)
        ])
        
        // Assemble Text Input
        let textContainer = UIView()
        textContainer.translatesAutoresizingMaskIntoConstraints = false
        textContainer.addSubview(textView)
        textContainer.addSubview(placeholderLabel)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: textContainer.topAnchor),
            textView.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 150), // Min height
            
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 4)
        ])
        
        // Assemble Tags
        tagsScrollView.addSubview(tagsStack)
        fillTags()
        
        let tagsContainer = UIView()
        tagsContainer.translatesAutoresizingMaskIntoConstraints = false
        tagsContainer.addSubview(tagsLabel)
        tagsContainer.addSubview(tagsScrollView)
        
        NSLayoutConstraint.activate([
            tagsLabel.topAnchor.constraint(equalTo: tagsContainer.topAnchor),
            tagsLabel.leadingAnchor.constraint(equalTo: tagsContainer.leadingAnchor),
            
            tagsScrollView.topAnchor.constraint(equalTo: tagsLabel.bottomAnchor, constant: 12),
            tagsScrollView.leadingAnchor.constraint(equalTo: tagsContainer.leadingAnchor),
            tagsScrollView.trailingAnchor.constraint(equalTo: tagsContainer.trailingAnchor),
            tagsScrollView.bottomAnchor.constraint(equalTo: tagsContainer.bottomAnchor),
            tagsScrollView.heightAnchor.constraint(equalToConstant: 40),
            
            tagsStack.topAnchor.constraint(equalTo: tagsScrollView.contentLayoutGuide.topAnchor),
            tagsStack.leadingAnchor.constraint(equalTo: tagsScrollView.contentLayoutGuide.leadingAnchor),
            tagsStack.trailingAnchor.constraint(equalTo: tagsScrollView.contentLayoutGuide.trailingAnchor),
            tagsStack.bottomAnchor.constraint(equalTo: tagsScrollView.contentLayoutGuide.bottomAnchor),
            tagsStack.heightAnchor.constraint(equalTo: tagsScrollView.frameLayoutGuide.heightAnchor)
        ])
        
        // Assemble Anonymous Switch
        anonymousContainer.addSubview(anonymousIcon)
        anonymousContainer.addSubview(anonymousLabel)
        anonymousContainer.addSubview(anonymousSwitch)
        
        NSLayoutConstraint.activate([
            anonymousContainer.heightAnchor.constraint(equalToConstant: 60),
            
            anonymousIcon.leadingAnchor.constraint(equalTo: anonymousContainer.leadingAnchor, constant: 16),
            anonymousIcon.centerYAnchor.constraint(equalTo: anonymousContainer.centerYAnchor),
            anonymousIcon.widthAnchor.constraint(equalToConstant: 24),
            anonymousIcon.heightAnchor.constraint(equalToConstant: 24),
            
            anonymousLabel.leadingAnchor.constraint(equalTo: anonymousIcon.trailingAnchor, constant: 12),
            anonymousLabel.centerYAnchor.constraint(equalTo: anonymousContainer.centerYAnchor),
            
            anonymousSwitch.trailingAnchor.constraint(equalTo: anonymousContainer.trailingAnchor, constant: -16),
            anonymousSwitch.centerYAnchor.constraint(equalTo: anonymousContainer.centerYAnchor)
        ])
        
        // Add to Main Stack
        contentStack.addArrangedSubview(profileContainer)
        contentStack.addArrangedSubview(textContainer)
        contentStack.addArrangedSubview(tagsContainer)
        contentStack.addArrangedSubview(anonymousContainer)
        
        setupConstraints()
    }
    
    private func fillTags() {
        for tag in availableTags {
            let button = UIButton(type: .system)
            button.setTitle(tag, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            button.layer.cornerRadius = 16
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            button.addTarget(self, action: #selector(tagTapped(_:)), for: .touchUpInside)
            tagsStack.addArrangedSubview(button)
        }
    }
    
    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            headerTitle.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            headerTitle.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            postButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            postButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            postButton.heightAnchor.constraint(equalToConstant: 36),
            
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        postButton.addTarget(self, action: #selector(postButtonTapped), for: .touchUpInside)
        anonymousSwitch.addTarget(self, action: #selector(anonymousToggled(_:)), for: .valueChanged)
    }
    
    // MARK: - Handlers
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func postButtonTapped() {
        guard !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // Shake animation or alert could be added here
            return
        }
        
        print("Posting...")
        print("Text: \(textView.text ?? "")")
        print("Tag: \(selectedTagButton?.titleLabel?.text ?? "None")")
        print("Anonymous: \(anonymousSwitch.isOn)")
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func tagTapped(_ sender: UIButton) {
        // Deselect previous
        if let previous = selectedTagButton {
            previous.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            previous.setTitleColor(.white, for: .normal)
        }
        
        // Select new
        sender.backgroundColor = .white
        sender.setTitleColor(UIColor(named: "colors/Blue&Shades/blue-500"), for: .normal)
        selectedTagButton = sender
    }
    
    @objc private func anonymousToggled(_ sender: UISwitch) {
        if sender.isOn {
            nameLabel.text = "Anonymous"
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = .white
            privacyLabel.text = "Hidden Identity"
        } else {
            nameLabel.text = "Shyam" // Restore actual name
            avatarImageView.image = UIImage(named: "illustrations/homePets/profile")
            privacyLabel.text = "Public Post"
        }
    }
}

// MARK: - UITextViewDelegate
extension CreatePostViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}

