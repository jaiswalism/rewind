//
//  CreatePostViewController.swift
//  Rewind
//
//  Created by Shyam on 07/11/25.
//

import UIKit
import PhotosUI

class CreatePostViewController: UIViewController {

    // MARK: - UI Components
    
    // Gradient Background
    private let gradientLayer = CAGradientLayer()
    
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
        label.text = "Aviral Sharma"
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
    
    // Media Section
    private let mediaLabel: UILabel = {
        let label = UILabel()
        label.text = "Add Media"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let mediaScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.heightAnchor.constraint(equalToConstant: 100).isActive = true
        return sv
    }()
    
    private let mediaStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center

        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let addMediaButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        button.setImage(UIImage(systemName: "camera.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 80).isActive = true
        button.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return button
    }()
    
    private var selectedImages: [UIImage] = []
    
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
    
    
    private var currentUser: User?
    private var postToEdit: CommunityPost? // Edit Mode Property
    
    init(postToEdit: CommunityPost? = nil) {
        self.postToEdit = postToEdit
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        fetchUserProfile()
        
        if let post = postToEdit {
            setupEditMode(post: post)
        }
    }
    
    private func setupEditMode(post: CommunityPost) {
        headerTitle.text = "Edit Post"
        postButton.setTitle("Update", for: .normal)
        
        textView.text = post.content
        placeholderLabel.isHidden = true
        
        anonymousSwitch.isOn = post.isAnonymous
        // Trigger toggle logic manually to update UI labels
        anonymousToggled(anonymousSwitch)
        
        addMediaButton.isHidden = true 
        mediaLabel.text = "Media (Editing not supported yet)"
        
    }
    
    
    private func fetchUserProfile() {
        UserService.shared.getProfile { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.currentUser = user
                    if !(self?.anonymousSwitch.isOn ?? false) {
                        self?.nameLabel.text = user.name
                    }
                case .failure(let error):
                    print("Error fetching profile: \(error)")
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupUI() {
        // Gradient Background
        view.backgroundColor = UIColor(named: "colors/Primary/Dark")
        gradientLayer.colors = [
            UIColor(named: "colors/Primary/Dark")?.cgColor ?? UIColor.black.cgColor,
            UIColor(named: "colors/Primary/Dark :hover")?.cgColor ?? UIColor.darkGray.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Header
        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(headerTitle)
        headerView.addSubview(postButton)
        
        // Main Content
        scrollView.contentInsetAdjustmentBehavior = .never

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        contentStack.addArrangedSubview(profileContainer)
        profileContainer.addSubview(avatarImageView)
        profileContainer.addSubview(nameLabel)
        profileContainer.addSubview(privacyLabel)
        
        let textContainer = UIView()
        textContainer.translatesAutoresizingMaskIntoConstraints = false
        textContainer.addSubview(textView)
        textContainer.addSubview(placeholderLabel)
        contentStack.addArrangedSubview(textContainer)
        
        contentStack.addArrangedSubview(mediaLabel)
        contentStack.addArrangedSubview(mediaScrollView)
        mediaScrollView.addSubview(mediaStack)
        mediaStack.addArrangedSubview(addMediaButton)
        
        contentStack.addArrangedSubview(tagsLabel)
        contentStack.addArrangedSubview(tagsScrollView)
        tagsScrollView.addSubview(tagsStack)
        populateTags()
        
        contentStack.addArrangedSubview(anonymousContainer)
        anonymousContainer.addSubview(anonymousIcon)
        anonymousContainer.addSubview(anonymousLabel)
        anonymousContainer.addSubview(anonymousSwitch)
        
        setupConstraints(textContainer: textContainer)
    }
    
    private func setupConstraints(textContainer: UIView) {
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            headerTitle.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            headerTitle.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            postButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            postButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            postButton.heightAnchor.constraint(equalToConstant: 36),
            
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Profile Section Constraints
            profileContainer.heightAnchor.constraint(equalToConstant: 60),
            avatarImageView.leadingAnchor.constraint(equalTo: profileContainer.leadingAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: profileContainer.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 48),
            avatarImageView.heightAnchor.constraint(equalToConstant: 48),
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 2),
            
            privacyLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            privacyLabel.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: -2),
            
            // Text Input Constraints
            textContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 150), // Changed to allow growth
            textView.topAnchor.constraint(equalTo: textContainer.topAnchor),
            textView.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),
            
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 5),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            
            // Media ScrollView
            mediaStack.topAnchor.constraint(equalTo: mediaScrollView.topAnchor),
            mediaStack.leadingAnchor.constraint(equalTo: mediaScrollView.leadingAnchor),
            mediaStack.trailingAnchor.constraint(equalTo: mediaScrollView.trailingAnchor),
            mediaStack.bottomAnchor.constraint(equalTo: mediaScrollView.bottomAnchor),
            mediaStack.heightAnchor.constraint(equalTo: mediaScrollView.heightAnchor),

            // Tags ScrollView
            tagsScrollView.heightAnchor.constraint(equalToConstant: 40),
            tagsStack.topAnchor.constraint(equalTo: tagsScrollView.topAnchor),
            tagsStack.leadingAnchor.constraint(equalTo: tagsScrollView.leadingAnchor),
            tagsStack.trailingAnchor.constraint(equalTo: tagsScrollView.trailingAnchor),
            tagsStack.bottomAnchor.constraint(equalTo: tagsScrollView.bottomAnchor),
            tagsStack.heightAnchor.constraint(equalTo: tagsScrollView.heightAnchor),
            
            // Anonymous Container
            anonymousContainer.heightAnchor.constraint(equalToConstant: 56),
            anonymousIcon.leadingAnchor.constraint(equalTo: anonymousContainer.leadingAnchor, constant: 16),
            anonymousIcon.centerYAnchor.constraint(equalTo: anonymousContainer.centerYAnchor),
            anonymousIcon.widthAnchor.constraint(equalToConstant: 24),
            anonymousIcon.heightAnchor.constraint(equalToConstant: 24),
            
            anonymousLabel.leadingAnchor.constraint(equalTo: anonymousIcon.trailingAnchor, constant: 12),
            anonymousLabel.centerYAnchor.constraint(equalTo: anonymousContainer.centerYAnchor),
            
            anonymousSwitch.trailingAnchor.constraint(equalTo: anonymousContainer.trailingAnchor, constant: -16),
            anonymousSwitch.centerYAnchor.constraint(equalTo: anonymousContainer.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        postButton.addTarget(self, action: #selector(postButtonTapped), for: .touchUpInside)
        anonymousSwitch.addTarget(self, action: #selector(anonymousToggled), for: .valueChanged)
        addMediaButton.addTarget(self, action: #selector(addMediaTapped), for: .touchUpInside)
    }
    
    private func populateTags() {
        for tag in availableTags {
            let button = UIButton(type: .system)
            button.setTitle(tag, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            button.tintColor = .white
            button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            button.layer.cornerRadius = 16
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            button.addTarget(self, action: #selector(tagTapped(_:)), for: .touchUpInside)
            tagsStack.addArrangedSubview(button)
        }
    }
    
    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    @objc private func addMediaTapped() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 4 - selectedImages.count // Max 4 images
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func postButtonTapped() {
        guard let content = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty else {
            return 
        }
        
        let isAnonymous = anonymousSwitch.isOn
        var tags: [String] = []
        if let selectedTag = selectedTagButton?.titleLabel?.text {
            tags.append(selectedTag)
        }
        
        // prevent double tapping
        postButton.isEnabled = false
        
        if let post = postToEdit {
            CommunityService.shared.updatePost(id: post.id, content: content, tags: tags) { [weak self] result in
                DispatchQueue.main.async {
                    self?.postButton.isEnabled = true
                    switch result {
                    case .success:
                        print("Post updated successfully")
                        NotificationCenter.default.post(name: NSNotification.Name("CommunityPostDeleted"), object: nil) // Triggers refresh
                        self?.navigationController?.popViewController(animated: true)
                    case .failure(let error):
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
            return
        }
        
        // CREATE MODE
        var mediaUrls: [String] = []
        if !selectedImages.isEmpty {
            // Save to Documents Directory for persistence
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            
            for (index, image) in selectedImages.enumerated() {
                if let data = image.jpegData(compressionQuality: 0.8) {
                    let filename = UUID().uuidString + ".jpg"
                    let fileUrl = documentsDirectory.appendingPathComponent(filename)
                    
                    do {
                        try data.write(to: fileUrl)
                        mediaUrls.append("local-image://\(filename)")
                    } catch {
                        print("Error saving image: \(error)")
                    }
                }
            }
        }
        
        CommunityService.shared.createPost(content: content, isAnonymous: isAnonymous, tags: tags, mediaUrls: mediaUrls) { [weak self] result in
            DispatchQueue.main.async {
                self?.postButton.isEnabled = true
                switch result {
                case .success(_):
                    print("Post created successfully")
                    NotificationCenter.default.post(name: NSNotification.Name("CommunityPostDeleted"), object: nil) // Refresh feed
                    self?.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
            nameLabel.text = currentUser?.name ?? "Me" // Restore actual name
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

// picker delegate stuff

extension CreatePostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self?.addSelectedImage(image)
                    }
                }
            }
        }
    }
    
    private func addSelectedImage(_ image: UIImage) {
        selectedImages.append(image)
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        let insertIndex = mediaStack.arrangedSubviews.count - 1
        mediaStack.insertArrangedSubview(imageView, at: insertIndex)
        
        if selectedImages.count >= 4 {
            addMediaButton.isHidden = true
        }
    }
}
