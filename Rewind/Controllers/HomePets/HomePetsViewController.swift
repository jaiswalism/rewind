//
//  HomePetsViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit
import SwiftUI

class HomePetsViewController: UIViewController {
    
    // MARK: - Properties
    private let customTabBar = CustomTabBar()
    private var penguinHostingController: UIHostingController<PenguinView>?
    @IBOutlet weak var petAreaView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomTabBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if penguinHostingController == nil && view.bounds.width > 0 && view.bounds.height > 0 {
            setupPenguinView()
        }
    }
    
    // MARK: - Setup
    private func setupCustomTabBar() {
        customTabBar.hostViewController = self
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customTabBar)
        
        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 10),
            customTabBar.heightAnchor.constraint(equalToConstant: 110)
        ])
    }
    
    private func setupPenguinView() {
        var petArea: UIView?
        
        if let petAreaView = petAreaView {
            petArea = petAreaView
        } else {
            func findMicButton(in view: UIView) -> UIButton? {
                for subview in view.subviews {
                    if let button = subview as? UIButton {
                        for target in button.allTargets {
                            let actions = button.actions(forTarget: target, forControlEvent: .touchUpInside) ?? []
                            if actions.contains(where: { $0.contains("micButtonTapped") }) {
                                return button
                            }
                        }
                    }
                    if let found = findMicButton(in: subview) {
                        return found
                    }
                }
                return nil
            }
            
            if let micButton = findMicButton(in: view) {
                petArea = micButton.superview
            }
            
            if petArea == nil {
                func findPetAreaBySize(in view: UIView) -> UIView? {
                    let width = view.bounds.width > 0 ? view.bounds.width : view.frame.width
                    let height = view.bounds.height > 0 ? view.bounds.height : view.frame.height
                    
                    if width > 320 && width < 370 && height > 420 && height < 500 {
                        if view.backgroundColor != nil {
                            return view
                        }
                    }
                    
                    for subview in view.subviews {
                        if let found = findPetAreaBySize(in: subview) {
                            return found
                        }
                    }
                    return nil
                }
                petArea = findPetAreaBySize(in: view)
            }
        }
        
        guard var finalPetArea = petArea else {
            return
        }
        
        if finalPetArea.frame.origin.y < 100 {
            func findBetterPetArea(in view: UIView, excluding: UIView) -> UIView? {
                for subview in view.subviews {
                    if subview === excluding { continue }
                    for button in subview.subviews where button is UIButton {
                        if let button = button as? UIButton {
                            for target in button.allTargets {
                                let actions = button.actions(forTarget: target, forControlEvent: .touchUpInside) ?? []
                                if actions.contains(where: { $0.contains("micButtonTapped") }) {
                                    return subview
                                }
                            }
                        }
                    }
                    if let found = findBetterPetArea(in: subview, excluding: excluding) {
                        return found
                    }
                }
                return nil
            }
            if let betterArea = findBetterPetArea(in: view, excluding: finalPetArea) {
                finalPetArea = betterArea
            }
        }
        
        let penguinView = PenguinView(
            mood: 70,
            energy: 60,
            behaviorPolicy: .silentCompanion
        )
        
        let hostingController = UIHostingController(rootView: penguinView)
        hostingController.view.backgroundColor = .clear
        
        addChild(hostingController)
        finalPetArea.insertSubview(hostingController.view, at: 0)
        hostingController.didMove(toParent: self)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.widthAnchor.constraint(equalToConstant: 280),
            hostingController.view.heightAnchor.constraint(equalToConstant: 280),
            hostingController.view.centerXAnchor.constraint(equalTo: finalPetArea.centerXAnchor),
            hostingController.view.centerYAnchor.constraint(equalTo: finalPetArea.centerYAnchor)
        ])
        
        finalPetArea.setNeedsLayout()
        finalPetArea.layoutIfNeeded()
        
        penguinHostingController = hostingController
    }
    @IBAction func buttontaped(_ sender: Any) {
        let notificationsVC = NotificationsViewController()
        if let navController = navigationController {
            navController.pushViewController(notificationsVC, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: notificationsVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
    
    @IBAction func settingsProfile(_ sender: Any) {
        let settingsVC = SettingsViewController()
        if let navController = navigationController {
            navController.pushViewController(settingsVC, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: settingsVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
    
    @IBAction func micButtonTapped(_ sender: Any) {
        let petTalkingVC = PetTalkingViewController()
        if let navController = navigationController {
            navController.pushViewController(petTalkingVC, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: petTalkingVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
}
