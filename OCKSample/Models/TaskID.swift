//
//  TaskID.swift
//  OCKSample
//
//  Created by Corey Baker on 4/14/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

enum TaskID {
    static let sleepingPill = "sleeping pills"
    static let cantSleep = "insomnia"
    static let getUp = "get up"
    static let breakfast = "eat breakfast"
    static let steps = "steps"

    static var ordered: [String] {
        [steps, sleepingPill, breakfast, getUp, cantSleep]
    }
}
