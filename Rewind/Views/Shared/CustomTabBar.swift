//
//  CustomTabBar.swift
//  Rewind
//
//

import UIKit

//
//  CustomTabBar.swift
//  Rewind
//
//
//

import UIKit

class CustomTabBar: UIView {
    
    weak var hostViewController: UIViewController?
    
    private let containerView = UIView()
    private var buttons: [UIButton] = []
    private var selectedIndex: Int = 1 // Default to center (paw icon)
    
    // Tab bar configuration
    private let tabBarHeight: CGFloat = 80 // Increased height for floating effect
    private let tabBarCornerRadius: CGFloat = 40
    
    // Centers the bar horizontally with padding
    private let horizontalPadding: CGFloat = 24
    
    // Tab items: journal, home (paw), care, community
    private let tabIcons = ["doc.text", "pawprint.fill", "brain.head.profile", "person.2"]
    
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
        
        // --- Premium Glass Container ---
        containerView.backgroundColor = .clear
        containerView.layer.cornerRadius = tabBarCornerRadius
        containerView.layer.masksToBounds = true // Clip blur and background
        
        // Glassmorphism Blur
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = containerView.bounds // Will be updated in layoutSubviews
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.isUserInteractionEnabled = false
        containerView.addSubview(blurView)
        
        // Semi-transparent overlay for tint
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-400")?.withAlphaComponent(0.2)
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(overlayView)
        
        // Border for definition
        containerView.layer.borderWidth = 1.0
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        addSubview(containerView)
        
        // Create tab buttons
        for (index, iconName) in tabIcons.enumerated() {
            let button = createTabButton(iconName: iconName, index: index)
            buttons.append(button)
            addSubview(button) // Buttons are added effectively above the container visually via layout
        }
        
        // Shadow for the Floating Effect
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.shadowRadius = 20
        
        updateButtonStates()
    }
    
    private func createTabButton(iconName: String, index: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = index
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        
        let isCenter = index == 1
        let pointSize: CGFloat = isCenter ? 28 : 22
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        let image = UIImage(systemName: iconName, withConfiguration: config)
        
        button.setImage(image, for: .normal)
        button.tintColor = .white
        
        // Add a subtle background glow/circle for buttons (optional, visible on selection)
        let indicatorView = UIView()
        indicatorView.tag = 99 // Identifier for the indicator
        indicatorView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        indicatorView.layer.cornerRadius = 25
        indicatorView.isUserInteractionEnabled = false
        indicatorView.isHidden = true // Hidden by default
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        button.insertSubview(indicatorView, at: 0)
        
        NSLayoutConstraint.activate([
            indicatorView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            indicatorView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            indicatorView.widthAnchor.constraint(equalToConstant: 50),
            indicatorView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        return button
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Floating Frame
        let containerWidth = bounds.width - (horizontalPadding * 2)
        containerView.frame = CGRect(
            x: horizontalPadding,
            y: 0,
            width: containerWidth,
            height: tabBarHeight
        )
        
        // Layout buttons evenly spaced within the container frame
        let buttonCount = CGFloat(buttons.count)
        let availableWidth = containerView.frame.width - 20 // 10pt padding inside container
        let buttonSpacing = availableWidth / buttonCount
        let startX = containerView.frame.minX + 10 // Start after inner padding
        
        for (index, button) in buttons.enumerated() {
            let xPosition = startX + (buttonSpacing * CGFloat(index)) + (buttonSpacing / 2)
            let buttonSize: CGFloat = 60
            
            button.frame = CGRect(
                x: xPosition - (buttonSize / 2),
                y: (tabBarHeight - buttonSize) / 2, // Vertically centered in bar
                width: buttonSize,
                height: buttonSize
            )
        }
    }
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        selectedIndex = index
        updateButtonStates()
        handleNavigation(for: index)
    }
    
    private func handleNavigation(for index: Int) {
        guard let parentVC = hostViewController else { return }
        
        let targetVC: UIViewController
        switch index {
        case 0:
            targetVC = JournalsHomeViewController(nibName: "JournalsHomeViewController", bundle: nil)
        case 1:
            targetVC = HomePetsViewController(nibName: "HomePetsViewController", bundle: nil)
        case 2:
            targetVC = CareCornerViewController()
        case 3:
            targetVC = CommunityFeedViewController(nibName: "CommunityFeedViewController", bundle: nil)
        default:
            return
        }
        
        // Navigation Logic
        if let navController = parentVC.navigationController {
            navController.setViewControllers([targetVC], animated: false) // Instant switch for tabs usually
        } else {
            let navController = UINavigationController(rootViewController: targetVC)
            navController.modalPresentationStyle = .fullScreen
            parentVC.present(navController, animated: false)
        }
    }
    
    private func updateButtonStates() {
        for (index, button) in buttons.enumerated() {
            let isSelected = index == selectedIndex
            
            // Animate Icon Scale
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
                button.transform = isSelected ? CGAffineTransform(scaleX: 1.1, y: 1.1) : .identity
                button.alpha = isSelected ? 1.0 : 0.6
                
                // Show/Hide custom indicator
                if let indicator = button.viewWithTag(99) {
                    indicator.isHidden = !isSelected
                    indicator.alpha = isSelected ? 1.0 : 0.0
                }
            }
        }
    }
    
    func selectTab(at index: Int) {
        guard index >= 0 && index < buttons.count else { return }
        selectedIndex = index
        updateButtonStates()
    }
}
