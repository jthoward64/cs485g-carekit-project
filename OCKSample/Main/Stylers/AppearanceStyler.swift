//
//  AppearanceStyler.swift
//  OCKSample
//
//  Created by Joshua Howard on 10/16/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI
import Foundation
import UIKit

struct AppearanceStyler: OCKAppearanceStyler {
    // MARK: Shadows

    var shadowOpacity1: Float { 0.20 }
    var shadowOffset1: CGSize { CGSize(width: 0.5, height: 2) }

    // MARK: Corners

    var cornerRadius1: CGFloat { 22 }
    var cornerRadius2: CGFloat { 18 }
}
