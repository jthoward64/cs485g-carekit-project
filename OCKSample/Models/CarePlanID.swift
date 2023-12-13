//
//  CarePlanID.swift
//  OCKSample
//
//  Created by Joshua Howard on 12/12/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

enum CarePlanID: String, CaseIterable, Identifiable {
    var id: Self { self }
    case health // Add custom id's for your Care Plans, these are examples
    case checkIn

    case insomnia
    case sleepingIn
}
