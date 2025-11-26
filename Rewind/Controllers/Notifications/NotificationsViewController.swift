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

    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let badgeLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 84/255, green: 72/255, blue: 233/255, alpha: 1)
        setupNavigationHeader()
        setupScrollStack()
        populateSampleContent()
    }

    private func setupNavigationHeader() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        let chevron = UIImage(systemName: "chevron.left")
        backButton.setImage(chevron, for: .normal)
        backButton.tintColor = UIColor.white.withAlphaComponent(0.95)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Notifications"
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .white
        view.addSubview(titleLabel)

        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.backgroundColor = UIColor(red: 75/255, green: 66/255, blue: 185/255, alpha: 1)
        badgeLabel.textColor = .white
        badgeLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        badgeLabel.text = "+11"
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 14
        badgeLabel.layer.masksToBounds = true
        view.addSubview(badgeLabel)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: safe.topAnchor, constant: 12),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: backButton.leadingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 14),

            badgeLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            badgeLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor, constant: -2),
            badgeLabel.widthAnchor.constraint(equalToConstant: 44),
            badgeLabel.heightAnchor.constraint(equalToConstant: 28)
        ])
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
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
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

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}
