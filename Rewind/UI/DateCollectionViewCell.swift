//
//  DateCollectionViewCell.swift
//  Rewind
//
//  Created by Shyam on 26/11/25.
//

import UIKit

class DateCollectionViewCell: UICollectionViewCell {
    static let identifier = "DateCell"
    
    // MARK: - UI Elements
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
        updateAppearance() // Set initial unselected state
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        // Use colors/Blue&Shades/blue-200 and colors/Primary/Light as seen in screenshot
        contentView.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-400")
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        
        let stackView = UIStackView(arrangedSubviews: [dayLabel, dateLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 2
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    private func updateAppearance() {
        let primaryLight = UIColor(named: "colors/Primary/Light") ?? .white
        let primaryBlue400 = UIColor(named: "colors/Blue&Shades/blue-400") ?? .systemBlue
        let primaryBlue300 = UIColor(named: "colors/Blue&Shades/blue-300") ?? .systemPurple

        // **Selected State** (Blue Background, White Text)
        if isSelected {
            contentView.backgroundColor = primaryLight
            dayLabel.textColor = primaryBlue400
            dateLabel.textColor = primaryBlue400
        }
        // **Unselected State** (Translucent Background, White Text)
        else {
            contentView.backgroundColor = primaryBlue300
            dayLabel.textColor = primaryLight
            dateLabel.textColor = primaryLight
        }
    }
    
    func configure(day: String, date: String) {
        dayLabel.text = day
        dateLabel.text = date
    }
}

class GlassBackButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Modern iOS 15+ Configuration
        var config = UIButton.Configuration.plain()
        
        // Icon
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        config.image = UIImage(systemName: "chevron.left", withConfiguration: symbolConfig)
        config.baseForegroundColor = .white // Icon color
        config.imagePadding = 0
        
        // Background with Glass Effect
        // Using '.systemMaterial' is the standard "Apple Glass" (adaptive, slightly translucent blur).
        // Removed border to match native style.
        var background = UIBackgroundConfiguration.clear()
        background.visualEffect = UIBlurEffect(style: .systemMaterial)
        background.cornerRadius = 22
        // background.strokeColor = UIColor.white.withAlphaComponent(0.3) // Removed border
        // background.strokeWidth = 1.0 // Removed border
        
        config.background = background
        config.cornerStyle = .capsule
        
        // Apply configuration
        self.configuration = config
        
        // Size
        if frame.size == .zero {
            frame.size = CGSize(width: 44, height: 44)
        }
        
        // Shadow for depth (Subtle native shadow)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.15
        
        accessibilityLabel = "Back"
    }
    
    // Helper to add to a view controller
    static func add(to viewController: UIViewController, action: Selector) {
        let button = GlassBackButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(viewController, action: action, for: .touchUpInside)
        
        viewController.view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            button.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 24),
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}
