//
//  Survey.swift
//  OCKSample
//
//  Created by Joshua Howard on 12/12/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Foundation

enum Survey: String, CaseIterable, Identifiable {
    var id: Self { self }
    case onboard
    case checkIn = "check in"
    case rangeOfMotion = "range of motion"

    func type() -> Surveyable {
        switch self {
        case .onboard:
            return Onboard()
        case .checkIn:
            return CheckIn()
        case .rangeOfMotion:
            return RangeOfMotion()
        }
    }
}
