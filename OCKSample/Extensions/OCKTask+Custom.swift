//
//  OCKTask+Custom.swift
//  OCKSample
//
//  Created by Joshua Howard on 12/12/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Foundation

extension OCKTask {
    var card: CareKitCard {
        get {
            guard let cardInfo = userInfo?[Constants.card],
                  let careKitCard = CareKitCard(rawValue: cardInfo)
            else {
                // The default is gridTask
                return .gridTask
            }
            return careKitCard
        }
        set {
            if userInfo == nil {
                // If the user doens't exist, make a default one
                userInfo = .init()
            }
            // ... and store the card type
            userInfo?[Constants.card] = newValue.rawValue
        }
    }
}
