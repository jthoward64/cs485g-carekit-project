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
    static let morningWalk = "morning walk"
    static let breakfast = "eat breakfast"
    static let sleepTemp = "sleep temperature"
    static let link = "link"
    static let reflect = "reflect"

    static var ordered: [String] {
        [link, sleepTemp, sleepingPill, morningWalk, breakfast, getUp, cantSleep, reflect]
    }
}
