import UIKit
import SwiftUI

final class CareCornerViewController: UIHostingController<CareCornerView> {
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        let placeholderView = CareCornerView(
            onBreathingTapped: {},
            onMeditationTapped: {}
        )
        super.init(rootView: placeholderView)
        rootView = CareCornerView(
            onBreathingTapped: { [weak self] in
                self?.showBreathingExercise()
            },
            onMeditationTapped: { [weak self] in
                self?.showMeditationSession()
            }
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func showBreathingExercise() {
        let breathingVC = BreathingExerciseViewController()
        breathingVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(breathingVC, animated: true)
    }

    private func showMeditationSession() {
        let meditationVC = MeditationViewController()
        meditationVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(meditationVC, animated: true)
    }
}
