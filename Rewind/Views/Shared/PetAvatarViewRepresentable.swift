import SwiftUI
import SceneKit

struct PetAvatarViewRepresentable: UIViewRepresentable {
    var scale: Float = 0.13
    var position: SCNVector3 = SCNVector3(0, -1.8, 0)
    
    func makeUIView(context: Context) -> PetAvatarView {
        let petView = PetAvatarView()
        petView.enableCameraControl(true)
        // Configure is safe to call here — it only stores pending values since
        // the model loads asynchronously. The SceneKit culling crash is prevented
        // separately via the layoutSubviews pause/resume in PetAvatarView itself.
        petView.configure(scale: scale, position: position)
        return petView
    }
    
    func updateUIView(_ uiView: PetAvatarView, context: Context) {
        // Configuration is applied once on makeUIView; no need to re-apply here.
    }
}
