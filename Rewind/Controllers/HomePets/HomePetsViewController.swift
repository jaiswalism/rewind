//
//  HomePetsViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit
import SceneKit

class HomePetsViewController: UIViewController {
    
    // MARK: - Properties
    
    // Pet UI
    private let petContainer = UIView()
    private let petImageView = UIImageView()
    private let petView = PetAvatarView()
    
    private let nameLabel = UILabel()
    private let levelLabel = UILabel()
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTabBar()
        
        // Ensure buttons stay on top of the 3D view
        view.subviews.forEach { subview in
            if subview is UIButton {
                view.bringSubviewToFront(subview)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchPetData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-400") ?? .systemBlue
        
        // Setup Pet Container
        petContainer.translatesAutoresizingMaskIntoConstraints = false
        petContainer.isUserInteractionEnabled = true
        view.addSubview(petContainer)
        
        // Pet Scene View (3D)
        petView.translatesAutoresizingMaskIntoConstraints = false
        petContainer.addSubview(petView)
        
        // Pet Image (Fallback)
        petImageView.translatesAutoresizingMaskIntoConstraints = false
        petImageView.contentMode = .scaleAspectFit
        petImageView.image = UIImage(systemName: "hare.fill") 
        petImageView.tintColor = .white
        petImageView.isHidden = true
        petContainer.addSubview(petImageView)
        
        // Name Label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        nameLabel.text = "Loading..."
        petContainer.addSubview(nameLabel)
        
        // Level Label
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        levelLabel.font = .systemFont(ofSize: 16, weight: .medium)
        levelLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        levelLabel.textAlignment = .center
        levelLabel.text = "Level 1"
        petContainer.addSubview(levelLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            petContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            petContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor), 
            petContainer.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40),
            petContainer.heightAnchor.constraint(equalToConstant: 420),
            
            // 3D View Constraints
            petView.centerXAnchor.constraint(equalTo: petContainer.centerXAnchor),
            petView.topAnchor.constraint(equalTo: petContainer.topAnchor),
            petView.widthAnchor.constraint(equalToConstant: 380), 
            petView.heightAnchor.constraint(equalToConstant: 380), 
            
            // 2D Image Constraints
            petImageView.centerXAnchor.constraint(equalTo: petContainer.centerXAnchor),
            petImageView.topAnchor.constraint(equalTo: petContainer.topAnchor),
            petImageView.widthAnchor.constraint(equalToConstant: 220),
            petImageView.heightAnchor.constraint(equalToConstant: 220),
            
            nameLabel.topAnchor.constraint(equalTo: petView.bottomAnchor, constant: -50), // Increased negative spacing to bring text closer to penguin
            nameLabel.leadingAnchor.constraint(equalTo: petContainer.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: petContainer.trailingAnchor),
            
            levelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4), // Reduced spacing
            levelLabel.leadingAnchor.constraint(equalTo: petContainer.leadingAnchor),
            levelLabel.trailingAnchor.constraint(equalTo: petContainer.trailingAnchor)
        ])
        
        // Load 3D Penguin
        petView.enableCameraControl(true)
        petView.configure(scale: 0.13, position: SCNVector3(0, -1.8, 0))
    }

    
    // MARK: - Tab Bar Setup
    private func setupTabBar() {
        let tabBarController = UITabBarController()
        
        let customTabBar = CustomTabBar()
        tabBarController.setValue(customTabBar, forKey: "tabBar")
        
        // Create navigation controllers for each tab
        let homePetsVC = self
        homePetsVC.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "pawprint"),
            selectedImage: UIImage(systemName: "pawprint.fill")
        )
        let homePetsNav = UINavigationController(rootViewController: homePetsVC)
        
        let journalsVC = JournalsHomeViewController(nibName: "JournalsHomeViewController", bundle: nil)
        journalsVC.tabBarItem = UITabBarItem(
            title: "Journal",
            image: UIImage(systemName: "doc.text"),
            selectedImage: UIImage(systemName: "doc.text.fill")
        )
        let journalsNav = UINavigationController(rootViewController: journalsVC)
        
        let careCornerVC = CareCornerViewController()
        careCornerVC.tabBarItem = UITabBarItem(
            title: "Care",
            image: UIImage(systemName: "brain.head.profile"),
            selectedImage: UIImage(systemName: "brain.head.profile.fill")
        )
        let careCornerNav = UINavigationController(rootViewController: careCornerVC)
        
        let communityVC = CommunityFeedViewController(nibName: "CommunityFeedViewController", bundle: nil)
        communityVC.tabBarItem = UITabBarItem(
            title: "Community",
            image: UIImage(systemName: "person.2"),
            selectedImage: UIImage(systemName: "person.2.fill")
        )
        let communityNav = UINavigationController(rootViewController: communityVC)
        
        // Set view controllers - Home is now at index 0
        tabBarController.viewControllers = [homePetsNav, journalsNav, careCornerNav, communityNav]
        tabBarController.selectedIndex = 0 // Select Home tab (now at index 0)
        
        // Present the tab bar controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBarController
        }
    }
    
    // MARK: - API
    private func fetchPetData() {
        HomePetService.shared.getPet { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let pet):
                    self?.updatePetUI(pet)
                case .failure(let error):
                    print("Error fetching pet: \(error)")

                    self?.nameLabel.text = "My Pet"
                }
            }
        }
    }
    
    private func updatePetUI(_ pet: Pet) {
        nameLabel.text = pet.name
        levelLabel.text = "Level \(pet.level)"
        
        let imageName = pet.type.lowercased() == "cat" ? "cat.fill" : "dog.fill"
        if let assetImage = UIImage(named: "illustrations/homePets/\(pet.type)") {
             petImageView.image = assetImage
        } else {
             petImageView.image = UIImage(systemName: imageName)
        }
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
        // limit taps
        if let navController = navigationController, navController.topViewController is PetTalkingViewController {
            return
        }
        if presentedViewController is PetTalkingViewController {
            return
        }
        
        print("Mic button tapped - navigating to PetTalkingViewController") // Debug log

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
