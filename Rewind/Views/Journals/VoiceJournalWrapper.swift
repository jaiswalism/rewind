import SwiftUI
import UIKit

struct VoiceJournalWrapper: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = VoiceJournalViewController(nibName: "VoiceJournalViewController", bundle: nil)
        // VoiceJournalViewController expects to be pushed, but we can embed it in a nav controller
        // and add a close button if needed, or rely on its internal Close button.
        let navController = UINavigationController(rootViewController: vc)
        navController.isNavigationBarHidden = true
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
