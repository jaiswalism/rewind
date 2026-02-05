//
//  PetAvatarView.swift
//  Rewind
//
//  Display logic for the 3D Pet Avatar
//

import UIKit
import SceneKit

class PetAvatarView: SCNView {
    
    // MARK: - Properties
    var penguinNode: SCNNode?
    
    // MARK: - Init
    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect, options: [String : Any]? = nil) {
        super.init(frame: frame, options: options)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        self.backgroundColor = .clear
        self.allowsCameraControl = true
        self.autoenablesDefaultLighting = true
        self.antialiasingMode = .multisampling4X
        
        let scene = SCNScene()
        self.scene = scene
        
        setupLighting(in: scene)
        loadPetModel()
    }
    
    // MARK: - Setup
    private func setupLighting(in scene: SCNScene) {
        // Shared lighting setup
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
    }
    
    private func loadPetModel() {
        // Try different paths - prioritized list
        var modelURL: URL?
        
        if let url = Bundle.main.url(forResource: "penguin 2", withExtension: "usdz") {
            modelURL = url
        } else if let url = Bundle.main.url(forResource: "penguin", withExtension: "usdz") {
            modelURL = url
        } else if let url = Bundle.main.url(forResource: "Resources/penguin 2", withExtension: "usdz") {
            modelURL = url
        }
        
        if let validURL = modelURL {
            loadModel(from: validURL)
        } else {
            print("❌ PetAvatarView: Failed to find penguin.usdz file")
            // Could implement a fallback placeholder here if desired
        }
    }
    
    private func loadModel(from url: URL) {
        // Load on background thread to prevent blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let petScene = try SCNScene(url: url)
                
                // Process the node
                if let petNode = petScene.rootNode.childNodes.first {
                    
                    // Normalizing the pivot (Calculations are fast, can be done here)
                    let (min, max) = petNode.boundingBox
                    let center = SCNVector3(
                        x: (min.x + max.x) / 2,
                        y: (min.y + max.y) / 2,
                        z: (min.z + max.z) / 2
                    )
                    
                    // Dispatch UI updates to main thread
                    DispatchQueue.main.async {
                        guard let scene = self.scene else { return }
                        
                        self.penguinNode = petNode
                        // Set pivot
                        petNode.pivot = SCNMatrix4MakeTranslation(center.x, min.y, center.z)
                        
                        scene.rootNode.addChildNode(petNode)
                        
                        // Start animation
                        self.startIdleAnimation()
                        
                        // Re-apply configuration if it was set pending load
                        // (Ideally we would store pending config, but for now we rely on the caller setting it)
                    }
                }
            } catch {
                print("❌ PetAvatarView: Failed to load pet model: \(error)")
            }
        }
    }
    
    // MARK: - Public API
    
    /// Configure the pet's size and position in the scene
    /// - Parameters:
    ///   - scale: The uniform scale factor
    ///   - position: The position vector (x, y, z)
    func configure(scale: Float, position: SCNVector3) {
        guard let penguin = penguinNode else { return }
        penguin.scale = SCNVector3(scale, scale, scale)
        penguin.position = position
    }
     
    func startIdleAnimation() {
        guard let penguin = penguinNode else { return }
        penguin.removeAction(forKey: "idle")
        
        let moveUp = SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: 2.0)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = SCNAction.moveBy(x: 0, y: -0.05, z: 0, duration: 2.0)
        moveDown.timingMode = .easeInEaseOut
        let bobSequence = SCNAction.sequence([moveUp, moveDown])
        let repeatBob = SCNAction.repeatForever(bobSequence)
        
        penguin.runAction(repeatBob, forKey: "idle")
    }
    
    // Allow adding a camera if needed (PetTalkingViewController uses one)
    func setupCamera(position: SCNVector3, lookAt: SCNVector3) {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = position
        cameraNode.look(at: lookAt)
        scene?.rootNode.addChildNode(cameraNode)
    }
    
    func enableCameraControl(_ enable: Bool) {
        self.allowsCameraControl = enable
    }
}
