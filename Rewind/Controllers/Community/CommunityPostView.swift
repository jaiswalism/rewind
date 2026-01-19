import UIKit

// Utility extension to find the nearest presenting UIViewController in the view hierarchy.
extension UIView {
    var parentViewController: UIViewController? {
        // Traverse the responder chain to find the UIViewController
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            responder = nextResponder
            if let viewController = responder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

// A custom UIView representing a single post in the community feed.
class CommunityPostView: UIView {
    
    // MARK: - Properties
    let postId: String // Added property
    let profileName: String
    let timestamp: String
    let postText: String
    let isAnonymous: Bool
    var likeCount: Int
    var commentCount: Int // Changed to var to update locally
    let isMine: Bool // Add isMine property
    let mediaUrls: [String]
    let tags: [String] // Added tags property
    
    // Internal state for the like button
    private var currentLikeState: Bool = false // Add currentLikeState property
    
    // Lazily initialized buttons connected to actions
    private lazy var likeButton: UIButton = {
        let button = createActionButton(
            iconName: self.currentLikeState ? "heart.fill" : "heart",
            count: self.likeCount,
            color: self.currentLikeState ? .systemRed : .white
        )
        button.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var commentButton: UIButton = {
        let button = createActionButton(
            iconName: "bubble.left.and.bubble.right.fill",
            count: self.commentCount,
            color: .white
        )
        button.addTarget(self, action: #selector(commentButtonTapped), for: .touchUpInside)
        return button
    }()

    // Share Button connected to action
    private lazy var shareButton: UIButton = {
        let button = createShareButton()
        button.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Components (Private)
    private let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1) // Semi-transparent based
        view.layer.cornerRadius = 24 // Increased radius
        view.clipsToBounds = true
        
        // Border
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        
        return view
    }()
    
    // ... [Reuse existing components] ...
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let innerStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 15
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        return stack
    }()
    
    // MARK: - Initialization
    init(postId: String, profileName: String, timestamp: String, postText: String, isAnonymous: Bool, likeCount: Int, commentCount: Int, isLiked: Bool, isMine: Bool, mediaUrls: [String]? = nil, tags: [String] = []) {
        self.postId = postId
        self.profileName = profileName
        self.timestamp = timestamp
        self.postText = postText
        self.isAnonymous = isAnonymous
        self.likeCount = likeCount
        self.commentCount = commentCount
        // self.isLiked = isLiked // Removed key
        self.currentLikeState = isLiked
        self.isMine = isMine
        self.mediaUrls = mediaUrls ?? []
        self.tags = tags
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        
        // Shadow for the card itself
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        
        addSubview(cardView)
        
        // Insert blur into cardView
        cardView.addSubview(blurView)
        cardView.addSubview(innerStack)
        
        // Constraints for blur to fill card
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: cardView.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor)
        ])
        
        // Populate the stack view
        innerStack.addArrangedSubview(createUserHeader())
        innerStack.addArrangedSubview(createPostLabel()) // Always add text
        
        // Conditionally add media preview
        if !mediaUrls.isEmpty {
            innerStack.addArrangedSubview(createMediaPreview())
        }
        
        // Add a vertical spacer before the actions view
        let actionSpacer = UIView()
        actionSpacer.heightAnchor.constraint(equalToConstant: 5).isActive = true
        innerStack.addArrangedSubview(actionSpacer)
        
        innerStack.addArrangedSubview(createActionsView())
        
        // Constraints to pin card to the edges of the view
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Inner Stack Constraints to pin to card edges (using layoutMargins for padding)
            innerStack.topAnchor.constraint(equalTo: cardView.topAnchor),
            innerStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            innerStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            innerStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
        ])
    }
    // MARK: - Action Handlers
    
    @objc private func likeButtonTapped(sender: UIButton) {
        // Optimistic UI Update
        currentLikeState.toggle()
        if currentLikeState {
            likeCount += 1
            CommunityService.shared.likePost(id: postId) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        self.likeCount = response.likeCount // Sync with server
                        self.updateLikeButton(sender: sender)
                    case .failure(let error):
                        print("Error liking post: \(error)")
                        // Revert
                        self.currentLikeState.toggle()
                        self.likeCount -= 1
                        self.updateLikeButton(sender: sender)
                    }
                }
            }
        } else {
            likeCount -= 1
            CommunityService.shared.unlikePost(id: postId) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        self.likeCount = response.likeCount // Sync with server
                        self.updateLikeButton(sender: sender)
                    case .failure(let error):
                        print("Error unliking post: \(error)")
                        // Revert
                        self.currentLikeState.toggle()
                        self.likeCount += 1
                        self.updateLikeButton(sender: sender)
                    }
                }
            }
        }
        
        updateLikeButton(sender: sender)
        
        // Animation
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                sender.transform = .identity
            })
        }
    }
    
    private func updateLikeButton(sender: UIButton) {
        let iconName = currentLikeState ? "heart.fill" : "heart"
        let iconColor: UIColor = currentLikeState ? .systemRed : .white
        let newConfig = createActionButtonConfig(iconName: iconName, count: likeCount, color: iconColor)
        sender.configuration = newConfig
    }
    
    @objc private func commentButtonTapped(sender: UIButton) {
        guard let presentingVC = self.parentViewController else {
            print("ERROR: Could not find presenting view controller to show comment sheet.")
            return
        }

        let commentVC = CommentSheetViewController()
        commentVC.postId = self.postId // Pass postId
        
        // Set up presentation style for a modal sheet
        if #available(iOS 15.0, *) {
            // Use modern sheet presentation if available
            if let sheet = commentVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()] // Allow dragging between medium and full screen
                sheet.largestUndimmedDetentIdentifier = .medium
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            }
        } else {
            // Fallback for older versions
            commentVC.modalPresentationStyle = .pageSheet
        }
        
        presentingVC.present(commentVC, animated: true, completion: nil)
        
        // Animate button press
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                sender.transform = .identity
            })
        }
    }

    @objc private func shareButtonTapped() {
        guard let presentingVC = self.parentViewController else {
            print("ERROR: Could not find presenting view controller for Share Sheet.")
            return
        }

        let defaultShareText = "Check out this inspiring post by \(profileName) on Rewind: \(postText)"
        let postLink = URL(string: "https://rewind.app/post/share-id")!
        
        let items: [Any] = [defaultShareText, postLink]

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = shareButton
            popoverController.sourceRect = shareButton.bounds
        }
        
        presentingVC.present(activityVC, animated: true, completion: nil)
    }

    @objc private func menuButtonTapped(sender: UIButton) {
        guard let presentingVC = self.parentViewController else {
            print("ERROR: Could not find presenting view controller to show menu.")
            return
        }

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // 1. Conditional Actions (Show only if it is MY post)
        if isMine {
            // Edit Post
            actionSheet.addAction(UIAlertAction(title: "Edit Post", style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                // Reconstruct CommunityPost object for editing
                let post = CommunityPost(
                    id: self.postId,
                    content: self.postText,
                    isAnonymous: self.isAnonymous,
                    tags: self.tags,
                    mediaUrls: self.mediaUrls,
                    likeCount: self.likeCount,
                    commentCount: self.commentCount,
                    createdAt: self.timestamp, // Note: timestamp string passed, might not parse back to Date exactly if formatter logic differs but used valid 'createdAt' string in fetching. Ideally store original.
                    user: nil, // User not needed for edit logic significantly
                    isLikedByMe: self.currentLikeState,
                    isMine: true
                )
                
                let editVC = CreatePostViewController(postToEdit: post)
                
                // Check if we can push
                if let navigationController = presentingVC.navigationController {
                    navigationController.pushViewController(editVC, animated: true)
                } else {
                    presentingVC.present(editVC, animated: true, completion: nil)
                }
            })

            // Delete Post
            actionSheet.addAction(UIAlertAction(title: "Delete Post", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.deletePost()
            })
        }
        
        // 2. Standard Actions (Always available)

        // Report Post
        actionSheet.addAction(UIAlertAction(title: "Report Post", style: .default) { _ in
            print("Action: Report Post Tapped for post by \(self.profileName)")
        })

        // 3. Cancel
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // Ensure popover presentation on iPad is anchored to the sender button
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }

        presentingVC.present(actionSheet, animated: true, completion: nil)
    }

    // MARK: - Factory Methods
    
    private func createUserHeader() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let avatarSize: CGFloat = 40
        
        // 1. Profile Image/Icon
        let avatar = UIImageView()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        
        if isAnonymous {
            avatar.image = UIImage(systemName: "person.circle.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: avatarSize, weight: .regular))
            avatar.tintColor = .white
            avatar.backgroundColor = .clear // Transparent background for filled circle icon style OR update design
        } else {
            avatar.image = UIImage(systemName: "person.crop.circle.fill")
            avatar.tintColor = .white
            avatar.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            avatar.contentMode = .center
            avatar.layer.cornerRadius = avatarSize / 2
            avatar.clipsToBounds = true
        }
        
        avatar.widthAnchor.constraint(equalToConstant: avatarSize).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: avatarSize).isActive = true
        container.addSubview(avatar)
        
        // 2. Name & Timestamp Stack
        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = 2
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(infoStack)
        
        let nameLabel = UILabel()
        nameLabel.text = profileName
        nameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        nameLabel.textColor = .white
        
        let timeLabel = UILabel()
        timeLabel.text = timestamp
        timeLabel.font = .systemFont(ofSize: 13, weight: .medium)
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        
        infoStack.addArrangedSubview(nameLabel)
        infoStack.addArrangedSubview(timeLabel)
        
        // 3. Menu Button
        let menuButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        menuButton.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        menuButton.tintColor = UIColor.white.withAlphaComponent(0.8)
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        
        // CONNECT ACTION
        menuButton.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
        
        container.addSubview(menuButton)
        
        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            avatar.topAnchor.constraint(equalTo: container.topAnchor),
            avatar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            infoStack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
            infoStack.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            
            menuButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            menuButton.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
        ])
        
        return container
    }

    private func createPostLabel() -> UILabel {
        let label = UILabel()
        label.text = postText
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }
    
    private func createMediaPreview() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.cornerRadius = 16
        container.clipsToBounds = true
        container.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        // For now, just show the first image as a background if available
        // In a real app, use a carousel or grid
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        // Load image logic (simplified for prototype)
        if let firstUrl = mediaUrls.first {
            // Check for local persistence scheme
            if firstUrl.hasPrefix("local-image://") {
                let filename = firstUrl.replacingOccurrences(of: "local-image://", with: "")
                if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fileUrl = documentsDirectory.appendingPathComponent(filename)
                    if let data = try? Data(contentsOf: fileUrl) {
                        imageView.image = UIImage(data: data)
                    } else {
                        // Image file missing
                         imageView.image = UIImage(systemName: "photo")
                    }
                }
            } else if firstUrl.hasPrefix("file://"), let url = URL(string: firstUrl), let data = try? Data(contentsOf: url) {
                 imageView.image = UIImage(data: data)
            } else if firstUrl.hasPrefix("http") {
                // Async load remote image
                imageView.image = UIImage(systemName: "photo") // Placeholder
                DispatchQueue.global().async {
                    if let url = URL(string: firstUrl), let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async {
                            // Check if the cell is still displaying this URL (basic check)
                            // In a real reusable cell, we'd need more robust check or cancellation
                            imageView.image = UIImage(data: data)
                        }
                    }
                }
            } else {
                 imageView.image = UIImage(systemName: "photo")
            }
        }
        
        container.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        
        // Overlay count if more than 1
        if mediaUrls.count > 1 {
            let countLabel = UILabel()
            countLabel.text = "+\(mediaUrls.count - 1)"
            countLabel.font = .systemFont(ofSize: 16, weight: .bold)
            countLabel.textColor = .white
            countLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            countLabel.layer.cornerRadius = 12
            countLabel.clipsToBounds = true
            countLabel.textAlignment = .center
            countLabel.translatesAutoresizingMaskIntoConstraints = false
            
            container.addSubview(countLabel)
            
            NSLayoutConstraint.activate([
                countLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
                countLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
                countLabel.widthAnchor.constraint(equalToConstant: 40),
                countLabel.heightAnchor.constraint(equalToConstant: 24)
            ])
        }
        
        // Add Tap Gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMediaTap))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true
        
        return container
    }
    
    @objc private func handleMediaTap() {
        guard let presentingVC = self.parentViewController, !mediaUrls.isEmpty else { return }
        let galleryVC = PhotoGalleryViewController(mediaUrls: mediaUrls)
        presentingVC.present(galleryVC, animated: true, completion: nil)
    }
    
    private func createActionsView() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        // 1. Left Actions Stack (Like and Comment)
        let leftActionsStack = UIStackView()
        leftActionsStack.axis = .horizontal
        leftActionsStack.spacing = 20
        leftActionsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Use the lazy initialized button properties
        leftActionsStack.addArrangedSubview(likeButton)
        leftActionsStack.addArrangedSubview(commentButton)
        
        // 2. Share Button (Pinned right)
        let shareButton = self.shareButton // Use lazy initialized property
        
        // 3. Central Spacer (Pushes the right content away)
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        
        // 4. Outer Stack (To spread left stack and right button)
        let outerStack = UIStackView(arrangedSubviews: [leftActionsStack, spacer, shareButton])
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        outerStack.axis = .horizontal
        outerStack.alignment = .center
        outerStack.distribution = .fill
        
        container.addSubview(outerStack)
        
        // Pin the outer stack to the full width and vertical center of the container
        NSLayoutConstraint.activate([
            outerStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            outerStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            outerStack.topAnchor.constraint(equalTo: container.topAnchor),
            outerStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            // Ensure spacer pushes components apart
            spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ])
        
        return container
    }
    
    // Helper function to generate the Configuration to be used by the buttons
    private func createActionButtonConfig(iconName: String, count: Int, color: UIColor) -> UIButton.Configuration {
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let iconImage = UIImage(systemName: iconName, withConfiguration: iconConfig)
        
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.image = iconImage
        
        let titleText = "\(count)"
        var attributes = AttributeContainer()
        attributes.font = .systemFont(ofSize: 16, weight: .bold)
        attributes.foregroundColor = color
        
        buttonConfig.attributedTitle = AttributedString(titleText, attributes: attributes)
        
        buttonConfig.imagePlacement = .leading
        buttonConfig.imagePadding = 5
        
        buttonConfig.baseForegroundColor = color
        
        // Apply vertical inset for proper vertical alignment
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)
        
        return buttonConfig
    }

    // Helper to generate a complete Action Button (Heart/Comment)
    private func createActionButton(iconName: String, count: Int, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        
        button.configuration = createActionButtonConfig(iconName: iconName, count: count, color: color)
        button.contentVerticalAlignment = .center
        
        return button
    }
    
    private func createShareButton() -> UIButton {
        let button = UIButton(type: .system)
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let image = UIImage(systemName: "square.and.arrow.up.fill", withConfiguration: iconConfig)
        
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.image = image
        
        let titleText = "Share"
        var attributes = AttributeContainer()
        attributes.font = .systemFont(ofSize: 16, weight: .bold)
        attributes.foregroundColor = .white
        
        buttonConfig.attributedTitle = AttributedString(titleText, attributes: attributes)
        
        buttonConfig.imagePlacement = .leading
        buttonConfig.imagePadding = 5
        
        buttonConfig.baseForegroundColor = .white
        
        // Apply vertical inset for proper vertical alignment
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)
        
        button.configuration = buttonConfig
        
        return button
    }
    
    private func deletePost() {
        CommunityService.shared.deletePost(id: postId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Post deleted successfully")
                    NotificationCenter.default.post(name: NSNotification.Name("CommunityPostDeleted"), object: nil)
                case .failure(let error):
                    print("Error deleting post: \(error)")
                }
            }
        }
    }
}
