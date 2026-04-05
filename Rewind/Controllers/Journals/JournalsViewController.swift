import UIKit
import SwiftUI

class JournalsViewController: UIHostingController<JournalsView> {
    
    init() {
        super.init(rootView: JournalsView())
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}
