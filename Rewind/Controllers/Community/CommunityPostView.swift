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
    let profileName: String
    let timestamp: String
    let postText: String
    let isAnonymous: Bool
    var likeCount: Int
    let commentCount: Int
    
    // Internal state for the like button
    private var isLiked: Bool = false
    
    // Lazily initialized buttons connected to actions
    private lazy var likeButton: UIButton = {
        let button = createActionButton(
            iconName: self.isLiked ? "heart.fill" : "heart",
            count: self.likeCount,
            color: self.isLiked ? .systemRed : .white
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
    init(profileName: String, timestamp: String, postText: String, isAnonymous: Bool, likeCount: Int, commentCount: Int) {
        self.profileName = profileName
        self.timestamp = timestamp
        self.postText = postText
        self.isAnonymous = isAnonymous
        self.likeCount = likeCount
        self.commentCount = commentCount
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
        innerStack.addArrangedSubview(createPostLabel())
        innerStack.addArrangedSubview(createMediaPreview())
        
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
        isLiked.toggle()
        
        if isLiked {
            likeCount += 1
        } else {
            likeCount -= 1
        }
        
        let iconName = isLiked ? "heart.fill" : "heart"
        let iconColor: UIColor = isLiked ? .systemRed : .white

        let newConfig = createActionButtonConfig(iconName: iconName, count: likeCount, color: iconColor)
        sender.configuration = newConfig
        
        // Play a subtle animation
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                sender.transform = .identity
            })
        }
    }
    
    @objc private func commentButtonTapped(sender: UIButton) {
        guard let presentingVC = self.parentViewController else {
            print("ERROR: Could not find presenting view controller to show comment sheet.")
            return
        }

        let commentVC = CommentSheetViewController()
        
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

        // 1. Conditional Actions (Show for non-anonymous/user's assumed posts)
        if !isAnonymous {
            // Edit Post
            actionSheet.addAction(UIAlertAction(title: "Edit Post", style: .default) { _ in
                print("Action: Edit Post Tapped for post by \(self.profileName)")
            })

            // Delete Post
            actionSheet.addAction(UIAlertAction(title: "Delete Post", style: .destructive) { _ in
                print("Action: Delete Post Tapped for post by \(self.profileName)")
            })
        }
        
        // 2. Standard Actions (Always available)

        // Hide Post
        actionSheet.addAction(UIAlertAction(title: "Hide Post", style: .default) { _ in
            print("Action: Hide Post Tapped for post by \(self.profileName)")
        })

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
        
        // Background Image (Leaf Pattern - Placeholder)
        let bgImage = UIImageView()
        bgImage.backgroundColor = .darkGray
        bgImage.contentMode = .scaleAspectFill
        bgImage.layer.opacity = 0.7
        bgImage.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bgImage)
        
        // Avatars Stack (Horizontal)
        let avatarsStack = UIStackView()
        avatarsStack.translatesAutoresizingMaskIntoConstraints = false
        avatarsStack.axis = .horizontal
        avatarsStack.spacing = 5
        
        // Create repeating avatar elements
        let avatar1 = createMediaAvatar(isOverlay: false)
        let avatar2 = createMediaAvatar(isOverlay: false)
        avatarsStack.addArrangedSubview(avatar1)
        avatarsStack.addArrangedSubview(avatar2)
        
        // Add the third element (either Camera Overlay or third Avatar)
        if isAnonymous {
            avatarsStack.addArrangedSubview(createMediaAvatar(isOverlay: false))
        } else {
            avatarsStack.addArrangedSubview(createMediaAvatar(isOverlay: true))
        }
        
        container.addSubview(avatarsStack)
        
        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: container.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            // Pin stack to the left and bottom, inside the rounded container
            avatarsStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            avatarsStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        return container
    }
    
    private func createMediaAvatar(isOverlay: Bool) -> UIView {
        let size: CGFloat = 40
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        
        view.widthAnchor.constraint(equalToConstant: size).isActive = true
        view.heightAnchor.constraint(equalToConstant: size).isActive = true
        
        let icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFill
        
        if isOverlay {
            // Camera Overlay Style (Rectangle with dark background)
            view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            icon.image = UIImage(systemName: "camera.fill")
            icon.tintColor = .white
            
            // Text "+4"
            let label = UILabel()
            label.text = "4"
            label.font = .systemFont(ofSize: 16, weight: .bold)
            label.textColor = .white
            
            let stack = UIStackView(arrangedSubviews: [icon, label])
            stack.axis = .horizontal
            stack.spacing = 2
            stack.alignment = .center
            stack.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(stack)
            
            NSLayoutConstraint.activate([
                stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        } else {
            // Figure Style (Placeholder for actual image, light rectangular background)
            view.backgroundColor = .lightGray
            icon.image = UIImage(systemName: "figure.walk")
            icon.tintColor = .black
            view.addSubview(icon)
            
            NSLayoutConstraint.activate([
                icon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                icon.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                icon.widthAnchor.constraint(equalToConstant: 30),
                icon.heightAnchor.constraint(equalToConstant: 30)
            ])
        }
        
        return view
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
        
        button.contentVerticalAlignment = .center
        button.configuration = buttonConfig
        
        return button
    }
}
