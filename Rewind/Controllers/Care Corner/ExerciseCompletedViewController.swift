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
    
    private let illustrationImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        return imageView
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Back to Care Corner", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitleColor(UIColor(red: 0.35, green: 0.38, blue: 0.75, alpha: 1.0), for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 28
        return button
    }()
    
    // MARK: - Properties
    private var gradientLayer: CAGradientLayer?
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
        setupUI()
        setupActions()
        updateLabels()
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
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(durationBadge)
        durationBadge.addSubview(durationIcon)
        durationBadge.addSubview(durationLabel)
        contentView.addSubview(pawsBadge)
        pawsBadge.addSubview(pawsLabel)
        contentView.addSubview(illustrationImageView)
        view.addSubview(backButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: backButton.topAnchor, constant: -20),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 80),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -30),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            // Duration Badge
            durationBadge.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            durationBadge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            durationBadge.heightAnchor.constraint(equalToConstant: 44),
            durationBadge.widthAnchor.constraint(equalToConstant: 200),
            
            // Duration Icon
            durationIcon.leadingAnchor.constraint(equalTo: durationBadge.leadingAnchor, constant: 16),
            durationIcon.centerYAnchor.constraint(equalTo: durationBadge.centerYAnchor),
            durationIcon.widthAnchor.constraint(equalToConstant: 20),
            durationIcon.heightAnchor.constraint(equalToConstant: 20),
            
            // Duration Label
            durationLabel.leadingAnchor.constraint(equalTo: durationIcon.trailingAnchor, constant: 8),
            durationLabel.centerYAnchor.constraint(equalTo: durationBadge.centerYAnchor),
            durationLabel.trailingAnchor.constraint(lessThanOrEqualTo: durationBadge.trailingAnchor, constant: -16),
            
            // Paws Badge
            pawsBadge.topAnchor.constraint(equalTo: durationBadge.bottomAnchor, constant: 12),
            pawsBadge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            pawsBadge.heightAnchor.constraint(equalToConstant: 44),
            pawsBadge.widthAnchor.constraint(equalToConstant: 220),
            
            // Paws Label
            pawsLabel.centerXAnchor.constraint(equalTo: pawsBadge.centerXAnchor),
            pawsLabel.centerYAnchor.constraint(equalTo: pawsBadge.centerYAnchor),
            
            // Illustration
            illustrationImageView.topAnchor.constraint(equalTo: pawsBadge.bottomAnchor, constant: 20),
            illustrationImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            illustrationImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            illustrationImageView.heightAnchor.constraint(equalToConstant: 400),
            illustrationImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Back Button
            backButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
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
        // Navigate back to Care Corner (pop to root or specific view controller)
        if let navigationController = navigationController {
            // Find Care Corner in the navigation stack
            for viewController in navigationController.viewControllers {
                if viewController is CareCornerViewController {
                    navigationController.popToViewController(viewController, animated: true)
                    return
                }
            }
            // If not found, pop to root
            navigationController.popToRootViewController(animated: true)
        }
    }
}
