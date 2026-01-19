//
//  CommunityFeedViewController.swift
//  Rewind
//
//  Created by Shyam on 07/11/25.
//

import UIKit

class CommunityFeedViewController: UIViewController {

    // MARK: - UI Components (Structural)
    
    // Fixed container for the top non-scrolling elements (Profile Bar and Tags)
    private let fixedHeaderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-400")
        return view
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        return scrollView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        return stackView
    }()
    
    private let customTabBar = CustomTabBar()

    // MARK: - UI Components (Header Content)
    private var profileBar: UIView!
    private var tagsView: UIView!
    
    // Gradient Layer Property
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - Data
    private var posts: [CommunityPost] = []
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Community"
        
        setupUI()
        fetchPosts()
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshPosts), name: NSNotification.Name("CommunityPostDeleted"), object: nil)
        setupCustomTabBar()
        setupRefreshControl()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchPosts()
        updateProfileBar()
    }
    
    private func setupRefreshControl() {
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(refreshPosts), for: .valueChanged)
        scrollView.refreshControl = refreshControl
    }
    
    @objc private func refreshPosts() {
        fetchPosts()
    }
    
    private func fetchPosts() {
        CommunityService.shared.getPosts { [weak self] result in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                switch result {
                case .success(let fetchedPosts):
                    print("📥 Fetched \(fetchedPosts.count) posts") // Debug Log
                    self?.posts = fetchedPosts
                    self?.setupContent()
                case .failure(let error):
                    print("❌ Error fetching posts: \(error)")
                }
            }
        }
    }
    
    private func updateProfileBar() {
        UserService.shared.getProfile { result in
            DispatchQueue.main.async {
                if case .success(let user) = result {
                    print("User profile loaded: \(user.name)")
                }
            }
        }
    }

    // MARK: - Content Population
    private func setupContent() {
        // Clear existing content
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if posts.isEmpty {
            // Show empty state?
            let label = UILabel()
            label.text = "No posts yet. Be the first!"
            label.textColor = .white
            label.textAlignment = .center
            contentStackView.addArrangedSubview(label)
        } else {
            for post in posts {
                // Determine display name
                let name = post.isAnonymous ? "Anonymous" : (post.user?.name ?? "Unknown")
                
                // Format Time
                let timeAgo = "Just now" // Placeholder, needs date logic
                
                let postView = CommunityPostView(
                    postId: post.id,
                    profileName: name,
                    timestamp: timeAgo,
                    postText: post.content,
                    isAnonymous: post.isAnonymous,
                    likeCount: post.likeCount,
                    commentCount: post.commentCount,
                    isLiked: post.isLikedByMe ?? false, // Use backend state
                    isMine: post.isMine ?? false, // Pass isMine
                    mediaUrls: post.mediaUrls,
                    tags: post.tags // Pass tags
                )
                
                let wrapper = createWrapperView(for: postView, horizontalPadding: 20)
                contentStackView.addArrangedSubview(wrapper)
            }
        }
        
        // Final Spacer
        let customTabBarHeight: CGFloat = 110.0
        let bottomSafeAreaMargin: CGFloat = 20.0
        let finalSpacer = UIView()
        finalSpacer.translatesAutoresizingMaskIntoConstraints = false
        finalSpacer.heightAnchor.constraint(equalToConstant: customTabBarHeight + bottomSafeAreaMargin).isActive = true
        contentStackView.addArrangedSubview(finalSpacer)
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Restore the navigation bar for other view controllers
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // FIX: Update gradient frame to match current view bounds (handling safe areas/resizing)
        gradientLayer?.frame = view.bounds
    }
    
    // MARK: - Setup
    private func setupUI() {
        // --- 1. Premium Gradient Background (Lighter) ---
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        self.gradientLayer = gradientLayer // Store reference
        // Lighter Gradient using named colors
        let startColor = UIColor(named: "colors/Blue&Shades/blue-400")?.cgColor ?? UIColor.systemBlue.cgColor
        let endColor = UIColor(named: "colors/Blue&Shades/blue-600")?.cgColor ?? UIColor.blue.cgColor
        
        gradientLayer.colors = [startColor, endColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // --- 2. Initialize properties ---
        profileBar = createProfileBar()
        tagsView = createTagsView()
        
        // --- 3. Glassmorphic Header ---
        setupGlassHeader()
        
        // --- 4. Add components to view hierarchy ---
        scrollView.backgroundColor = .clear // FIX: Ensure transparent
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        scrollView.addSubview(contentStackView)
        view.addSubview(fixedHeaderView)
        
        // Add header content
        fixedHeaderView.addSubview(profileBar)
        fixedHeaderView.addSubview(tagsView)

        // --- 5. Apply Constraints ---
        setupConstraints()
    }
    
    private func setupGlassHeader() {
        fixedHeaderView.backgroundColor = .clear
        
        // Add Blur
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        fixedHeaderView.insertSubview(blurView, at: 0)
        
        // Add minimal border
        let borderView = UIView()
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        fixedHeaderView.addSubview(borderView)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: fixedHeaderView.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: fixedHeaderView.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: fixedHeaderView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: fixedHeaderView.trailingAnchor),
            
            borderView.heightAnchor.constraint(equalToConstant: 1),
            borderView.bottomAnchor.constraint(equalTo: fixedHeaderView.bottomAnchor),
            borderView.leadingAnchor.constraint(equalTo: fixedHeaderView.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: fixedHeaderView.trailingAnchor)
        ])
    }
    
    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        
        // --- Fixed Header Constraints ---
        NSLayoutConstraint.activate([
            fixedHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
            fixedHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fixedHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        // --- Fixed Header Internal Constraints ---
        NSLayoutConstraint.activate([
            profileBar.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 5),
            profileBar.leadingAnchor.constraint(equalTo: fixedHeaderView.leadingAnchor),
            profileBar.trailingAnchor.constraint(equalTo: fixedHeaderView.trailingAnchor),
            
            tagsView.topAnchor.constraint(equalTo: profileBar.bottomAnchor, constant: 10),
            tagsView.leadingAnchor.constraint(equalTo: fixedHeaderView.leadingAnchor),
            tagsView.trailingAnchor.constraint(equalTo: fixedHeaderView.trailingAnchor),
            tagsView.bottomAnchor.constraint(equalTo: fixedHeaderView.bottomAnchor, constant: -15),
        ])
        
        // --- Custom Tab Bar Constraints ---
        view.addSubview(customTabBar)
        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 10),
            customTabBar.heightAnchor.constraint(equalToConstant: 110)
        ])
        
        // --- Scroll View Constraints (Full Screen) ---
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // --- Content Stack View Constraints ---
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        ])
        
        // Adjust padding to ensure first post is visible below header
        contentStackView.layoutMargins = UIEdgeInsets(top: 180, left: 0, bottom: 100, right: 0) // Increased Top + Bottom padding for TabBar
        contentStackView.isLayoutMarginsRelativeArrangement = true
    }
    
    private func setupCustomTabBar() {
        customTabBar.hostViewController = self
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        customTabBar.selectTab(at: 3) // Select Community tab (index 3)
    }


    
    // Utility to wrap a view and apply padding
    private func createWrapperView(for view: UIView, horizontalPadding: CGFloat) -> UIView {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: wrapper.topAnchor),
            view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: horizontalPadding),
            view.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -horizontalPadding),
        ])
        
        // Ensures the wrapper height wraps the internal view's height
        wrapper.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        
        return wrapper
    }

    // MARK: - Fixed Header Content Factory Methods
    
    private func createProfileBar() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 60).isActive = true

        // Profile Avatar (Aviral Sharma)
        let avatar = UIImageView(image: UIImage(named: "illustrations/homePets/profile"))
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 30
        avatar.clipsToBounds = true
        view.addSubview(avatar)
        
        // Name & Post Count Stack
        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = 2
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoStack)
        
        let nameLabel = UILabel()
        nameLabel.text = "Aviral Sharma"
        nameLabel.font = .systemFont(ofSize: 18, weight: .bold)
        nameLabel.textColor = .white
        
        let countLabel = UILabel()
        countLabel.text = "25 Total Posts"
        countLabel.font = .systemFont(ofSize: 14, weight: .medium)
        countLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        
        infoStack.addArrangedSubview(nameLabel)
        infoStack.addArrangedSubview(countLabel)

        // Plus Button
        let plusButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        let plusImage = UIImage(systemName: "plus.circle.fill", withConfiguration: config)
        plusButton.setImage(plusImage, for: .normal)
        plusButton.tintColor = .white
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        view.addSubview(plusButton)

        NSLayoutConstraint.activate([
            // Avatar
            avatar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            avatar.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 60),
            avatar.heightAnchor.constraint(equalToConstant: 60),
            
            // Info Stack
            infoStack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            infoStack.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            
            // Plus Button
            plusButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            plusButton.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
        ])
        
        return view
    }
    
    private func createTagsView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // "Browse By" Label
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Browse By"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        view.addSubview(label)
        
        // Tags Scroll View (for horizontal scrolling tags)
        let tagsScrollView = UIScrollView()
        tagsScrollView.translatesAutoresizingMaskIntoConstraints = false
        tagsScrollView.showsHorizontalScrollIndicator = false
        view.addSubview(tagsScrollView)
        
        // Tags Stack View (inside tagsScrollView)
        let tags = ["TRENDING", "STRESS", "ANXIETY", "AFFIRMATION", "GRATITUDE", "DAILY"]
        let tagsStackView = UIStackView()
        tagsStackView.translatesAutoresizingMaskIntoConstraints = false
        tagsStackView.axis = .horizontal
        tagsStackView.spacing = 8
        tagsStackView.alignment = .fill
        
        for tag in tags {
            let button = createTagButton(title: tag)
            tagsStackView.addArrangedSubview(button)
        }
        tagsScrollView.addSubview(tagsStackView)
        
        let contentLayout = tagsScrollView.contentLayoutGuide
        let frameLayout = tagsScrollView.frameLayoutGuide

        NSLayoutConstraint.activate([
            // Label
            label.topAnchor.constraint(equalTo: view.topAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            
            // Tags Scroll View
            tagsScrollView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            tagsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            tagsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tagsScrollView.heightAnchor.constraint(equalToConstant: 45), // Fixed height for button row
            tagsScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Tags Stack Constraints
            tagsStackView.topAnchor.constraint(equalTo: contentLayout.topAnchor),
            tagsStackView.leadingAnchor.constraint(equalTo: contentLayout.leadingAnchor),
            tagsStackView.trailingAnchor.constraint(equalTo: contentLayout.trailingAnchor, constant: -24), // Right padding for last tag
            tagsStackView.bottomAnchor.constraint(equalTo: contentLayout.bottomAnchor),
            tagsStackView.heightAnchor.constraint(equalTo: frameLayout.heightAnchor)
        ])
        
        return view
    }
    
    private func createTagButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        
        var config = UIButton.Configuration.filled()
        config.title = title
        
        // FIX: Apply smaller size (13pt)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .semibold)
            return outgoing
        }
        
        // FIX: Reduced padding for smaller button size
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        
        // Apply "colors/Primary/Darker" color
        // Apply lighter color as requested (blue-500)
        config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.2)
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        
        button.configuration = config
        return button
    }

    // MARK: - Actions
    @objc private func plusButtonTapped() {
        let createPostVC = CreatePostViewController()
        navigationController?.pushViewController(createPostVC, animated: true)
    }
}

// MARK: - Photo Gallery (Moved here to ensure visibility without project file modification)

class PhotoGalleryViewController: UIViewController {

    // MARK: - Properties
    private let mediaUrls: [String]
    private let initialIndex: Int
    
    private var pageViewController: UIPageViewController!
    private var photoViewControllers: [UIViewController] = []
    
    // MARK: - UI Components
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    init(mediaUrls: [String], initialIndex: Int = 0) {
        self.mediaUrls = mediaUrls
        self.initialIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupPageViewController()
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
    }
    
    private func setupPageViewController() {
        // Create view controllers for each image
        for (index, url) in mediaUrls.enumerated() {
            let photoVC = SinglePhotoViewController(url: url, index: index, total: mediaUrls.count)
            photoViewControllers.append(photoVC)
        }
        
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        // Set initial view controller
        if initialIndex < photoViewControllers.count {
            pageViewController.setViewControllers([photoViewControllers[initialIndex]], direction: .forward, animated: false, completion: nil)
        }
        
        addChild(pageViewController)
        view.insertSubview(pageViewController.view, at: 0)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        pageViewController.didMove(toParent: self)
    }
    
    @objc private func handleClose() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIPageViewControllerDataSource
extension PhotoGalleryViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let photoVC = viewController as? SinglePhotoViewController,
              let index = photoViewControllers.firstIndex(of: photoVC),
              index > 0 else {
            return nil
        }
        return photoViewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let photoVC = viewController as? SinglePhotoViewController,
              let index = photoViewControllers.firstIndex(of: photoVC),
              index < photoViewControllers.count - 1 else {
            return nil
        }
        return photoViewControllers[index + 1]
    }
}

// MARK: - Single Photo View Controller
class SinglePhotoViewController: UIViewController {
    
    private let urlString: String
    private let index: Int
    private let total: Int
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let counterLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(url: String, index: Int, total: Int) {
        self.urlString = url
        self.index = index
        self.total = total
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImage()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        view.addSubview(imageView)
        view.addSubview(counterLabel)
        
        counterLabel.text = "\(index + 1) / \(total)"
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            counterLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            counterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func loadImage() {
        if urlString.hasPrefix("local-image://") {
            let filename = urlString.replacingOccurrences(of: "local-image://", with: "")
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileUrl = documentsDirectory.appendingPathComponent(filename)
                if let data = try? Data(contentsOf: fileUrl) {
                    imageView.image = UIImage(data: data)
                } else {
                     imageView.image = UIImage(systemName: "photo")
                }
            }
        } else if urlString.hasPrefix("file://"), let url = URL(string: urlString), let data = try? Data(contentsOf: url) {
            imageView.image = UIImage(data: data)
        } else if urlString.hasPrefix("http") {
             // Placeholder for async loading
             imageView.image = UIImage(systemName: "photo")
             // In real app use Kingfisher or SDWebImage
             DispatchQueue.global().async {
                 if let url = URL(string: self.urlString), let data = try? Data(contentsOf: url) {
                     DispatchQueue.main.async {
                         self.imageView.image = UIImage(data: data)
                     }
                 }
             }
        } else {
             imageView.image = UIImage(systemName: "photo")
        }
    }
}
