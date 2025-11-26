//
//  NotificationsViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

struct NotificationItem {
    let icon: UIImage?
    let title: String
    let subtitle: String
}

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
        iconImageView.image = item.icon?.withRenderingMode(.alwaysTemplate)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
    }
}

class NotificationsViewController: UIViewController {

    // keep legacy outlet so existing xib/storyboard connections don't crash
    @IBOutlet weak var tag: UILabel?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

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
        // Ensure the system navigation bar is visible so the default back button appears when this VC is pushed.
        navigationController?.setNavigationBarHidden(false, animated: false)
        // Ensure the back button tint is visible against the dark bar
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barStyle = .black
        // Debug: print navigation state
        NSLog("[NotificationsVC] viewWillAppear - navigationController: %@", String(describing: navigationController))
        NSLog("[NotificationsVC] viewWillAppear - isNavigationBarHidden: %d", navigationController?.isNavigationBarHidden ?? false)
        NSLog("[NotificationsVC] viewWillAppear - nav stack count: %d", navigationController?.viewControllers.count ?? 0)
        NSLog("[NotificationsVC] viewWillAppear - hidesBackButton: %d", navigationItem.hidesBackButton)
        // If we're pushed and not the root, hide the in-view header so the system nav bar/back shows cleanly
        if let nav = navigationController, nav.viewControllers.firstIndex(of: self) ?? 0 > 0 {
            // Nothing to toggle; relying on system navigation bar for title/back.
        }
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

        // Sync in-view header visibility again after appearance
        if let nav = navigationController, nav.viewControllers.firstIndex(of: self) ?? 0 > 0 {
            // Nothing to toggle; relying on system navigation bar for title/back.
        } else {
            // Nothing to toggle; relying on system navigation bar for title/back.
        }
        // Debug: print navigation state after appear
        NSLog("[NotificationsVC] viewDidAppear - navigationController: %@", String(describing: navigationController))
        NSLog("[NotificationsVC] viewDidAppear - isNavigationBarHidden: %d", navigationController?.isNavigationBarHidden ?? false)
        NSLog("[NotificationsVC] viewDidAppear - nav stack count: %d", navigationController?.viewControllers.count ?? 0)
        NSLog("[NotificationsVC] viewDidAppear - hidesBackButton: %d", navigationItem.hidesBackButton)

        // Show fallback back button when system nav bar is not available or hidden
        let navBarHidden = navigationController?.isNavigationBarHidden ?? true
        let hasNavController = (navigationController != nil)
        fallbackBackButton.isHidden = hasNavController && !navBarHidden
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 84/255, green: 72/255, blue: 233/255, alpha: 1)
        // Add fallback back button to view hierarchy (kept hidden unless needed)
        view.addSubview(fallbackBackButton)
        NSLayoutConstraint.activate([
            fallbackBackButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            fallbackBackButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            fallbackBackButton.widthAnchor.constraint(equalToConstant: 36),
            fallbackBackButton.heightAnchor.constraint(equalToConstant: 36)
        ])

        // No in-view header; rely on UINavigationBar for title/back
        setupScrollStack()
        populateSampleContent()

        // Title for system navigation bar (if present)
        navigationItem.title = "Notifications"

        // If this VC is presented modally or is the root of the nav stack, provide a close button.
        // When pushed onto a nav stack (and not root) the system back button will be shown automatically.
        if presentingViewController != nil || navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissTapped))
        }
    }

    @objc private func dismissTapped() {
        if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func fallbackBackTapped() {
        // Mirror dismissTapped behavior for fallback button
        if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        } else if navigationController != nil {
            navigationController?.popViewController(animated: true)
        } else {
            // As a last resort try to dismiss
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
            // Pin top to safe area (below nav bar when present)
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

    private func populateSampleContent() {
        // Earlier This Day
        stackView.addArrangedSubview(makeSectionHeader(title: "Earlier This Day"))

        let earlier = [
            NotificationItem(icon: UIImage(systemName: "doc.text"), title: "Journal Incomplete!", subtitle: "It's Reflection Time! ✍️"),
            NotificationItem(icon: UIImage(systemName: "heart"), title: "Exercise Complete!", subtitle: "22m Breathing Done. 🧘"),
            NotificationItem(icon: UIImage(systemName: "face.smiling"), title: "Mood Improved.", subtitle: "Neutral    →    Happy")
        ]

        for item in earlier {
            let card = NotificationCardView(item: item)
            stackView.addArrangedSubview(card)
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true
        }

        // spacing
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
        stackView.addArrangedSubview(spacer)

        // Last Week
        stackView.addArrangedSubview(makeSectionHeader(title: "Last Week"))

        let lastWeek = [
            NotificationItem(icon: UIImage(systemName: "doc.on.clipboard"), title: "Stress Decreased.", subtitle: "Stress Level is now 3."),
            NotificationItem(icon: UIImage(systemName: "face.smiling"), title: "Mood Improved.", subtitle: "Neutral    →    Happy"),
            NotificationItem(icon: UIImage(systemName: "face.smiling"), title: "Mood Improved.", subtitle: "Neutral    →    Happy")
        ]

        for item in lastWeek {
            let card = NotificationCardView(item: item)
            stackView.addArrangedSubview(card)
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true
        }

        // Add bottom padding so last card isn't flush to bottom
        let bottomPad = UIView()
        bottomPad.translatesAutoresizingMaskIntoConstraints = false
        bottomPad.heightAnchor.constraint(equalToConstant: 36).isActive = true
        stackView.addArrangedSubview(bottomPad)
    }
}
