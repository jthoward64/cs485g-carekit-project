//
//  DimensionStyler.swift
//  OCKSample
//
//  Created by Joshua Howard on 10/16/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI
import UIKit

struct DimensionStyler: OCKDimensionStyler {
    #if os(iOS)
        var separatorHeight: CGFloat { 1.2 / UIScreen.main.scale }
    #endif

    var lineWidth1: CGFloat { 4 }
    var stackSpacing1: CGFloat { 14 }

    var imageHeight2: CGFloat { 50 }
    var imageHeight1: CGFloat { 180 }
}
