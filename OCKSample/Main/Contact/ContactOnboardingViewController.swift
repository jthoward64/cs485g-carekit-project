//
//  File.swift
//  OCKSample
//
//  Created by Joshua Howard on 12/13/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import UIKit

/*
 This isn't MVVM, and its not neccecary, but I wanted the contact page to look nice so I googled
 about 10 seconds worth of UIKit
 */

class ContactOnboardingViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .none
        title = "Onboarding Required"
    }

    // this view just shows a message saying to complete onboarding on the home tab
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        let label = UILabel()
        label.text = "Please complete onboarding on the home tab."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            label.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1.2)
        ])

        self.view = view
    }
}
