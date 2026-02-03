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
    private let penguinSceneView = SCNView()
    private var penguinNode: SCNNode?
    
    private let nameLabel = UILabel()
    private let levelLabel = UILabel()
    private let refreshControl = UIRefreshControl()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTabBar()
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
        
        // Pet Scene View (3D)
        setupPenguinSceneView()
        petContainer.addSubview(penguinSceneView)
        
        // Pet Image (Fallback)
        petImageView.translatesAutoresizingMaskIntoConstraints = false
        petImageView.contentMode = .scaleAspectFit
        petImageView.image = UIImage(systemName: "hare.fill") // Fallback
        petImageView.tintColor = .white
        petImageView.isHidden = true // Hidden by default, shown if 3D fails
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
            petContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor), // Centered vertically
            petContainer.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40),
            petContainer.heightAnchor.constraint(equalToConstant: 420), // Increased height for 3D model
            
            // 3D View Constraints
            penguinSceneView.centerXAnchor.constraint(equalTo: petContainer.centerXAnchor),
            penguinSceneView.topAnchor.constraint(equalTo: petContainer.topAnchor),
            penguinSceneView.widthAnchor.constraint(equalToConstant: 380), // Increased width
            penguinSceneView.heightAnchor.constraint(equalToConstant: 380), // Increased height
            
            // 2D Image Constraints (Fallback)
            petImageView.centerXAnchor.constraint(equalTo: petContainer.centerXAnchor),
            petImageView.topAnchor.constraint(equalTo: petContainer.topAnchor),
            petImageView.widthAnchor.constraint(equalToConstant: 220),
            petImageView.heightAnchor.constraint(equalToConstant: 220),
            
            nameLabel.topAnchor.constraint(equalTo: penguinSceneView.bottomAnchor, constant: -50), // Increased negative spacing to bring text closer to penguin
            nameLabel.leadingAnchor.constraint(equalTo: petContainer.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: petContainer.trailingAnchor),
            
            levelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4), // Reduced spacing
            levelLabel.leadingAnchor.constraint(equalTo: petContainer.leadingAnchor),
            levelLabel.trailingAnchor.constraint(equalTo: petContainer.trailingAnchor)
        ])
        
        // Load 3D Penguin
        setup3DPenguin()
    }

    
    // MARK: - Tab Bar Setup
    private func setupTabBar() {
        // Create a tab bar controller and embed this view controller in it
        let tabBarController = UITabBarController()
        
        // Replace with custom tab bar
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
    
    // MARK: - 3D Penguin Setup
    private func setupPenguinSceneView() {
        penguinSceneView.translatesAutoresizingMaskIntoConstraints = false
        penguinSceneView.backgroundColor = .clear
        penguinSceneView.allowsCameraControl = true // Allow user to rotate/interact
        penguinSceneView.autoenablesDefaultLighting = true
        penguinSceneView.antialiasingMode = .multisampling4X
        
        let scene = SCNScene()
        penguinSceneView.scene = scene
    }

    private func setup3DPenguin() {
        let scene = penguinSceneView.scene ?? SCNScene()
        penguinSceneView.scene = scene
        
        print("🔍 Looking for penguin 2.usdz for Home Screen...")
        
        // Try different paths - prioritized list
        if let modelURL = Bundle.main.url(forResource: "penguin 2", withExtension: "usdz") {
            print("✅ Found penguin 2.usdz at: \(modelURL)")
            loadPenguinModel(from: modelURL, into: scene)
        } else if let modelURL = Bundle.main.url(forResource: "penguin", withExtension: "usdz") {
            print("✅ Found penguin.usdz at: \(modelURL)")
            loadPenguinModel(from: modelURL, into: scene)
        } else if let modelURL = Bundle.main.url(forResource: "Resources/penguin 2", withExtension: "usdz") {
            print("✅ Found penguin 2.usdz in Resources at: \(modelURL)")
            loadPenguinModel(from: modelURL, into: scene)
        } else {
            print("❌ Failed to find penguin.usdz file")
            // Fallback to 2D image
            penguinSceneView.isHidden = true
            petImageView.isHidden = false
        }
    }
    
    private func loadPenguinModel(from url: URL, into scene: SCNScene) {
        do {
            let penguinScene = try SCNScene(url: url)
            
            if let penguin = penguinScene.rootNode.childNodes.first {
                penguinNode = penguin
                // Adjust position to be grounded
                penguin.position = SCNVector3(0, -1.4, 0)
                
                // Adjust scale - bigger
                let scale: Float = 0.13
                penguin.scale = SCNVector3(scale, scale, scale)
                
                scene.rootNode.addChildNode(penguin)
                
                // Lighting
                let lightNode = SCNNode()
                lightNode.light = SCNLight()
                lightNode.light?.type = .omni
                lightNode.light?.intensity = 1000
                lightNode.position = SCNVector3(0, 10, 10)
                scene.rootNode.addChildNode(lightNode)
                
                let ambientLightNode = SCNNode()
                ambientLightNode.light = SCNLight()
                ambientLightNode.light?.type = .ambient
                ambientLightNode.light?.color = UIColor.white.withAlphaComponent(0.8)
                ambientLightNode.light?.intensity = 500
                scene.rootNode.addChildNode(ambientLightNode)
                
                startPenguinIdleAnimation()
                
                penguinSceneView.isHidden = false
                petImageView.isHidden = true
                
                // Debug
                let (min, max) = penguin.boundingBox
                print("📏 Home Penguin bounding box: min=\(min), max=\(max)")
            } else {
                print("⚠️ Penguin scene loaded but no child nodes found")
                // Fallback
                penguinSceneView.isHidden = true
                petImageView.isHidden = false
            }
        } catch {
            print("❌ Failed to load penguin model: \(error)")
            // Fallback
            penguinSceneView.isHidden = true
            petImageView.isHidden = false
        }
    }
    
    private func startPenguinIdleAnimation() {
        guard let penguin = penguinNode else { return }
        
        let moveUp = SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: 2.0)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = SCNAction.moveBy(x: 0, y: -0.05, z: 0, duration: 2.0)
        moveDown.timingMode = .easeInEaseOut
        let bobSequence = SCNAction.sequence([moveUp, moveDown])
        let repeatBob = SCNAction.repeatForever(bobSequence)
        
        penguin.runAction(repeatBob, forKey: "homeBobbing")
    }
}
