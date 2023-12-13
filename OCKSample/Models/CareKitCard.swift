//
//  CareKitCard.swift
//  OCKSample
//
//  Created by Joshua Howard on 12/12/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
enum CareKitCard: String, CaseIterable, Identifiable {
    var id: Self { self }

    case instructionsTask = "Instructions"
    case simpleTask = "Simple"
    case checklist = "Checklist"
    case button = "Button"
    case gridTask = "Grid"
    case labeledValueTask = "Labeled Value"
    case link = "Link"
    case featuredContent = "Featured Content"
    case numericProgress = "Numeric Progress"
}
