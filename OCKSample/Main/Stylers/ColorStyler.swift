//
//  ColorStyler.swift
//  OCKSample
//
//  Created by Corey Baker on 10/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI
import UIKit

struct ColorStyler: OCKColorStyler {
    #if os(iOS)
        var separator: UIColor { #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1) }

        var customFill: UIColor { #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1) }

        var customBlue: UIColor { #colorLiteral(red: 0.2578051413, green: 0.1628935136, blue: 0.7159225001, alpha: 1) }

        var customGray: UIColor { #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1) }
    #endif
}
