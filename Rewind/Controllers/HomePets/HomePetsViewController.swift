//
//  HomePetsViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

class HomePetsViewController: UIViewController {
    
    // MARK: - Properties
    private let customTabBar = CustomTabBar()
    
    // Pet UI
    private let petContainer = UIView()
    private let petImageView = UIImageView()
    private let nameLabel = UILabel()
    private let levelLabel = UILabel()
    private let refreshControl = UIRefreshControl()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCustomTabBar()
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
        view.addSubview(petContainer)
        
        // Pet Image
        petImageView.translatesAutoresizingMaskIntoConstraints = false
        petImageView.contentMode = .scaleAspectFit
        petImageView.image = UIImage(systemName: "hare.fill") // Fallback
        petImageView.tintColor = .white
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
            petContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            petContainer.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40),
            petContainer.heightAnchor.constraint(equalToConstant: 300),
            
            petImageView.centerXAnchor.constraint(equalTo: petContainer.centerXAnchor),
            petImageView.topAnchor.constraint(equalTo: petContainer.topAnchor),
            petImageView.widthAnchor.constraint(equalToConstant: 180),
            petImageView.heightAnchor.constraint(equalToConstant: 180),
            
            nameLabel.topAnchor.constraint(equalTo: petImageView.bottomAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: petContainer.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: petContainer.trailingAnchor),
            
            levelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            levelLabel.leadingAnchor.constraint(equalTo: petContainer.leadingAnchor),
            levelLabel.trailingAnchor.constraint(equalTo: petContainer.trailingAnchor)
        ])
    }

    private func setupCustomTabBar() {
        customTabBar.hostViewController = self
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customTabBar)
        customTabBar.selectTab(at: 1) // Home (Paw) is index 1
        
        // Position tab bar at the very bottom of the screen
        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 10),
            customTabBar.heightAnchor.constraint(equalToConstant: 110)
        ])
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
                    // Optional: Show error state or keep default
                    self?.nameLabel.text = "My Pet"
                }
            }
        }
    }
    
    private func updatePetUI(_ pet: Pet) {
        nameLabel.text = pet.name
        levelLabel.text = "Level \(pet.level)"
        
        // Simple logic to choose image based on type/color
        // In a real app, this would use the asset catalog
        let imageName = pet.type.lowercased() == "cat" ? "cat.fill" : "dog.fill"
        // Try to load asset if available, else system
        if let assetImage = UIImage(named: "illustrations/homePets/\(pet.type)") {
             petImageView.image = assetImage
        } else {
             petImageView.image = UIImage(systemName: imageName)
        }
    }

    @IBAction func buttontaped(_ sender: Any) {
        // Present NotificationsViewController instead of Settings
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
