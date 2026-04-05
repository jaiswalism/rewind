import SwiftUI
import UIKit

struct CreatePostViewBridge: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CreatePostViewController {
        return CreatePostViewController()
    }
    
    func updateUIViewController(_ uiViewController: CreatePostViewController, context: Context) {
        // No updates needed
    }
}
