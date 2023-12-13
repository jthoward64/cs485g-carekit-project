//
//  MyContactView.swift
//  OCKSample
//
//  Created by Joshua Howard on 12/12/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import os.log
import SwiftUI
import UIKit

struct MyContactView: UIViewControllerRepresentable {
    @Environment(\.careStore) var careStore

    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = MyContactViewController(store: careStore)
        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType,
                                context: Context) {}
}

struct MyContactView_Previews: PreviewProvider {
    static var previews: some View {
        MyContactView()
            .environment(\.careStore, Utility.createPreviewStore())
            .accentColor(Color(TintColorKey.defaultValue))
    }
}
