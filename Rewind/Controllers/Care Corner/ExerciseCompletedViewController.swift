//
//  ExerciseCompletedViewController.swift
//  Rewind
//
//  Created on 11/26/25.
//

import UIKit

class ExerciseCompletedViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear 
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Exercise\nCompleted"
        label.font = UIFont.boldSystemFont(ofSize: 42)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Task is recorded.\nYou can continue your activity now!"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.alpha = 0.9
        return label
    }()
    
    // Custom Badge for Duration
    private let durationBadge: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 22
        return view
    }()
    
    private let durationIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        imageView.image = UIImage(systemName: "clock", withConfiguration: config)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "DURATION: 25M"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    // centering the icon and label

    private let durationStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }()
    
    // Custom Badge for Paws
    private let pawsBadge: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 22
        return view
    }()
    
    private let pawsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "100 PAWS CREDITED"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    // Background Illustration
    private let illustrationImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        // Use the asset name confirmed by the user
        imageView.image = UIImage(named: "illustrations/careCorner/ExCompleteBottomBG")
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // Main action button (at the bottom)
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Back to Care Corner", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitleColor(UIColor(named: "colors/Primary/Dark"), for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 28
        return button
    }()
    
    // MARK: - Properties
    private let duration: String
    private let pawsEarned: Int
    
    // MARK: - Init
    init(duration: String, pawsEarned: Int = 100) {
        self.duration = duration
        self.pawsEarned = pawsEarned
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.duration = "5M"
        self.pawsEarned = 100
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // hiding nav bar for immersion

        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupUI()
        setupActions()
        updateLabels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-400")
        
        // ADD ILLUSTRATION FIRST to the main view (static background)
        view.insertSubview(illustrationImageView, at: 0)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        view.addSubview(backButton)
        
        // ADD CONTENT ELEMENTS to the contentView (layered on top)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
        // Assemble duration badge using the Stack View
        durationStackView.addArrangedSubview(durationIcon)
        durationStackView.addArrangedSubview(durationLabel)
        durationBadge.addSubview(durationStackView)
        contentView.addSubview(durationBadge)
        
        // Assemble paws badge
        pawsBadge.addSubview(pawsLabel)
        contentView.addSubview(pawsBadge)
        
        setupConstraints()
    }

    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        
        // Constraints for the primary screen structure
        NSLayoutConstraint.activate([
            illustrationImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            illustrationImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            illustrationImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            illustrationImageView.heightAnchor.constraint(equalToConstant: 480),

            // --- Scroll View ---
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: backButton.topAnchor, constant: -20),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // --- Content Elements (Relative to safeArea/contentView top) ---

            // Title
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -30),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            // Duration Badge
            durationBadge.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            durationBadge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            durationBadge.heightAnchor.constraint(equalToConstant: 44),
            durationBadge.widthAnchor.constraint(equalToConstant: 200),
            
            // FIXED ALIGNMENT: Center the stack view inside the badge
            durationStackView.centerXAnchor.constraint(equalTo: durationBadge.centerXAnchor),
            durationStackView.centerYAnchor.constraint(equalTo: durationBadge.centerYAnchor),
            
            // Paws Badge
            pawsBadge.topAnchor.constraint(equalTo: durationBadge.bottomAnchor, constant: 12),
            pawsBadge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            pawsBadge.heightAnchor.constraint(equalToConstant: 44),
            pawsBadge.widthAnchor.constraint(equalToConstant: 220),
            
            // Paws Label
            pawsLabel.centerXAnchor.constraint(equalTo: pawsBadge.centerXAnchor),
            pawsLabel.centerYAnchor.constraint(equalTo: pawsBadge.centerYAnchor),
            
            // --- Main Action Button (Pinned to main view's safe area) ---
            backButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -30),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            backButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            backButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    private func updateLabels() {
        durationLabel.text = "DURATION: \(duration)"
        pawsLabel.text = "\(pawsEarned) PAWS CREDITED"
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        // Navigate back to Care Corner
        if let navigationController = navigationController {
            for viewController in navigationController.viewControllers.reversed() {
                if viewController is CareCornerViewController {
                    navigationController.popToViewController(viewController, animated: true)
                    return
                }
            }
            navigationController.popToRootViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
