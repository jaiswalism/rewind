//
//  PersonalInformationViewController.swift
//  Rewind
//
//  Created on 01/19/26.
//

import UIKit
import SwiftUI

class PersonalInformationViewController: UIHostingController<PersonalInformationView> {
    
    // MARK: - Init
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(rootView: PersonalInformationView())
        setupCallbacks()
    }
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Callbacks
    
    private func setupCallbacks() {
        var view = rootView
        
        view.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        rootView = view
    }
}
