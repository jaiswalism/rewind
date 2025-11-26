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
