//
//  NotificationsViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

final class NotificationCardView: UIView {
    private let container = UIView()
    private let leftCircle = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    init(item: NotificationItem) {
        super.init(frame: .zero)
        setupViews()
        configure(with: item)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(red: 147/255, green: 135/255, blue: 255/255, alpha: 1)
        container.layer.cornerRadius = 20
        container.layer.masksToBounds = false
        container.layer.shadowColor = UIColor.purple.cgColor
        container.layer.shadowOpacity = 0.12
        container.layer.shadowOffset = CGSize(width: 0, height: 6)
        container.layer.shadowRadius = 8

        addSubview(container)

        leftCircle.translatesAutoresizingMaskIntoConstraints = false
        leftCircle.backgroundColor = UIColor(red: 105/255, green: 98/255, blue: 231/255, alpha: 1)
        leftCircle.layer.cornerRadius = 28

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.tintColor = .white
        iconImageView.contentMode = .center

        leftCircle.addSubview(iconImageView)
        container.addSubview(leftCircle)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.numberOfLines = 2

        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 72),

            leftCircle.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            leftCircle.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            leftCircle.widthAnchor.constraint(equalToConstant: 56),
            leftCircle.heightAnchor.constraint(equalToConstant: 56),

            iconImageView.centerXAnchor.constraint(equalTo: leftCircle.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: leftCircle.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 26),
            iconImageView.heightAnchor.constraint(equalToConstant: 26),

            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leftCircle.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -12)
        ])
    }

    func configure(with item: NotificationItem) {
        // Map type to icon
        let iconName: String
        switch item.type {
        case "reminder": iconName = "bell.fill"
        case "alert": iconName = "exclamationmark.triangle.fill"
        case "info": iconName = "info.circle.fill"
        default: iconName = "doc.text.fill"
        }
        
        iconImageView.image = UIImage(systemName: iconName)?.withRenderingMode(.alwaysTemplate)
        titleLabel.text = item.title
        subtitleLabel.text = item.message
    }
}

class NotificationsViewController: UIViewController {

    // keep legacy outlet so existing xib/storyboard connections don't crash
    @IBOutlet weak var tag: UILabel?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let refreshControl = UIRefreshControl()

    // Fallback in-view back/close button (only shown when nav bar is absent/hidden)
    private lazy var fallbackBackButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(fallbackBackTapped), for: .touchUpInside)
        btn.isHidden = true
        return btn
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barStyle = .black
        fetchNotifications() // Fetch on appear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barStyle = .black
        navigationItem.hidesBackButton = false

        let navBarHidden = navigationController?.isNavigationBarHidden ?? true
        let hasNavController = (navigationController != nil)
        fallbackBackButton.isHidden = hasNavController && !navBarHidden
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 84/255, green: 72/255, blue: 233/255, alpha: 1)
        view.addSubview(fallbackBackButton)
        NSLayoutConstraint.activate([
            fallbackBackButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            fallbackBackButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            fallbackBackButton.widthAnchor.constraint(equalToConstant: 36),
            fallbackBackButton.heightAnchor.constraint(equalToConstant: 36)
        ])

        setupScrollStack()
        setupRefreshControl()
        
        navigationItem.title = "Notifications"

        if presentingViewController != nil || navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissTapped))
        }
    }
    
    private func setupRefreshControl() {
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(refreshNotifications), for: .valueChanged)
        scrollView.refreshControl = refreshControl
    }
    
    @objc private func refreshNotifications() {
        fetchNotifications()
    }

    @objc private func dismissTapped() {
        if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func fallbackBackTapped() {
        if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        } else if navigationController != nil {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    private func setupScrollStack() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        stackView.axis = .vertical
        stackView.spacing = 18
        stackView.alignment = .fill

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 18),
            scrollView.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: safe.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func makeSectionHeader(title: String) -> UILabel {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = title
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        lbl.textColor = UIColor.white.withAlphaComponent(0.9)
        return lbl
    }

    private func fetchNotifications() {
        NotificationService.shared.getNotifications { [weak self] result in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                switch result {
                case .success(let items):
                    self?.populateNotifications(items)
                case .failure(let error):
                    print("Error fetching notifications: \(error)")
                }
            }
        }
    }
    
    private func populateNotifications(_ items: [NotificationItem]) {
        // Clear Stack
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if items.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No new notifications."
            emptyLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            emptyLabel.textAlignment = .center
            stackView.addArrangedSubview(emptyLabel)
            return
        }
        
        // Simple grouping could be added here if dates were parsed
        // For now, just list them all
        
        for item in items {
            let card = NotificationCardView(item: item)
            stackView.addArrangedSubview(card)
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true
        }
        
        // Add bottom padding
        let bottomPad = UIView()
        bottomPad.translatesAutoresizingMaskIntoConstraints = false
        bottomPad.heightAnchor.constraint(equalToConstant: 36).isActive = true
        stackView.addArrangedSubview(bottomPad)
    }
}
