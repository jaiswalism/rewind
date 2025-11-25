//
//  CustomTabBar.swift
//  Rewind
//
//  Created by Kiro
//

import UIKit

protocol CustomTabBarDelegate: AnyObject {
    func tabBar(_ tabBar: CustomTabBar, didSelectItemAt index: Int)
}

class CustomTabBar: UIView {
    
    weak var delegate: CustomTabBarDelegate?
    
    private let containerView = UIView()
    private var buttons: [UIButton] = []
    private var selectedIndex: Int = 2 // Default to center (paw icon)
    
    // Tab bar configuration
    private let tabBarHeight: CGFloat = 70
    private let tabBarCornerRadius: CGFloat = 35
    private let centerButtonSize: CGFloat = 65
    private let regularIconSize: CGFloat = 28
    private let centerIconSize: CGFloat = 32
    
    // Colors matching the image - lighter semi-transparent purple
    private let tabBarColor = UIColor(red: 0.48, green: 0.52, blue: 0.82, alpha: 0.85) // Lighter semi-transparent purple
    private let centerButtonColor = UIColor.white
    private let iconColor = UIColor.white
    private let centerIconColor = UIColor(red: 0.48, green: 0.52, blue: 0.82, alpha: 1.0)
    
    // Tab items: journal, goals, home (paw), care, community
    private let tabIcons = ["doc.text", "chart.pie", "pawprint.fill", "brain.head.profile", "person.3"]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        
        // Setup container with rounded corners
        containerView.backgroundColor = tabBarColor
        containerView.layer.cornerRadius = tabBarCornerRadius
        containerView.layer.masksToBounds = true
        addSubview(containerView)
        
        // Create tab buttons
        for (index, iconName) in tabIcons.enumerated() {
            let button = createTabButton(iconName: iconName, index: index)
            buttons.append(button)
            containerView.addSubview(button)
        }
        
        // Highlight the center button initially
        updateButtonStates()
    }
    
    private func createTabButton(iconName: String, index: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = index
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        
        let config = UIImage.SymbolConfiguration(pointSize: index == 2 ? centerIconSize : regularIconSize, weight: .medium)
        let image = UIImage(systemName: iconName, withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = index == 2 ? centerIconColor : iconColor
        
        // Center button gets special styling
        if index == 2 {
            button.backgroundColor = centerButtonColor
            button.layer.cornerRadius = centerButtonSize / 2
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.layer.shadowRadius = 6
            button.layer.shadowOpacity = 0.2
            button.layer.masksToBounds = false
        }
        
        return button
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Layout container with minimal padding for wider look
        let horizontalPadding: CGFloat = 15
        containerView.frame = CGRect(
            x: horizontalPadding,
            y: 0,
            width: bounds.width - (horizontalPadding * 2),
            height: tabBarHeight
        )
        
        // Layout buttons
        let buttonCount = CGFloat(buttons.count)
        let buttonSpacing = containerView.bounds.width / buttonCount
        
        for (index, button) in buttons.enumerated() {
            let xPosition = buttonSpacing * CGFloat(index) + (buttonSpacing / 2)
            
            if index == 2 {
                // Center button (elevated)
                button.frame = CGRect(
                    x: xPosition - (centerButtonSize / 2),
                    y: (tabBarHeight - centerButtonSize) / 2 - 10, // Elevated above bar
                    width: centerButtonSize,
                    height: centerButtonSize
                )
            } else {
                // Regular buttons
                let buttonSize: CGFloat = 48
                button.frame = CGRect(
                    x: xPosition - (buttonSize / 2),
                    y: (tabBarHeight - buttonSize) / 2,
                    width: buttonSize,
                    height: buttonSize
                )
            }
        }
    }
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        selectedIndex = index
        updateButtonStates()
        delegate?.tabBar(self, didSelectItemAt: index)
    }
    
    private func updateButtonStates() {
        for (index, button) in buttons.enumerated() {
            if index == 2 {
                // Center button always has white background
                button.alpha = index == selectedIndex ? 1.0 : 0.7
            } else {
                button.alpha = index == selectedIndex ? 1.0 : 0.6
            }
        }
    }
    
    func selectTab(at index: Int) {
        guard index >= 0 && index < buttons.count else { return }
        selectedIndex = index
        updateButtonStates()
    }
}
