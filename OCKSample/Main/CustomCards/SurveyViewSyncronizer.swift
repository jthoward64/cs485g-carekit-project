//
//  SurveyViewSyncronizer.swift
//  OCKSample
//
//  Created by Joshua Howard on 12/12/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import CareKitUI
import os.log
import ResearchKit
import UIKit

final class SurveyViewSynchronizer: OCKSurveyTaskViewSynchronizer {
    override func updateView(_ view: OCKInstructionsTaskView,
                             context: OCKSynchronizationContext<OCKTaskEvents>) {
        super.updateView(view, context: context)

        if let event = context.viewModel.first?.first, event.outcome != nil {
            view.instructionsLabel.isHidden = false
            /*
             TODO: You need to modify this so the instuction label shows
             correctly for each Task/Card.
             Hint - Each event (OCKAnyEvent) has a task. How can you use
             this task to determine what instruction answers should show?
             Look at how the CareViewController differentiates between
             surveys.
             */
            switch Survey(rawValue: event.task.id) {
            case .onboard:
                view.instructionsLabel.text = "Onboarding complete"
            case .checkIn:
                let sleep = event.answer(kind: CheckIn.sleepItemIdentifier)
                let sleepQuality = event.answer(kind: CheckIn.sleepQualityItemIdentifier)
                let stayedUpLate = event.boolAnswer(kind: CheckIn.stayedUpLateItemIdentifier)
                let wakeOnTime = event.boolAnswer(kind: CheckIn.wakeOnTimeItemIdentifier)
                view.instructionsLabel.text = """
                Sleep: \(sleep) hours
                Sleep Quality: \(sleepQuality)/10
                Stayed up late: \(stayedUpLate ? "Yes" : "No")
                Woke on time: \(wakeOnTime ? "Yes" : "No")
                """
            default:
                view.instructionsLabel.text = "All done!"
            }

        } else {
            view.instructionsLabel.isHidden = true
        }
    }
}
