//
//  CustomTabBar.swift
//  Rewind
//
//

import UIKit

class CustomTabBar: UITabBar {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAppearance()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAppearance()
    }
    
    private func setupAppearance() {
        // Native liquid glass appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // System liquid glass background
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.1)
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        // Tab item styling
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.6),
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ]
        
        // Apply appearance
        standardAppearance = appearance
        scrollEdgeAppearance = appearance
        
        // Tint colors
        tintColor = UIColor.white
        unselectedItemTintColor = UIColor.white.withAlphaComponent(0.6)
        backgroundColor = UIColor.clear
        
        // Optional subtle border
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
    }
}