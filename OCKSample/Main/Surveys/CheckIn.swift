//
//  CheckIn.swift
//  OCKSample
//
//  Created by Joshua Howard on 12/12/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
#if canImport(ResearchKit)
import ResearchKit
#endif

struct CheckIn: Surveyable {
    static var surveyType: Survey {
        Survey.checkIn
    }

    static var formIdentifier: String {
        "\(identifier()).form"
    }

    static var sleepItemIdentifier: String {
        "\(identifier()).form.sleep"
    }

    static var stayedUpLateItemIdentifier: String {
        "\(identifier()).form.stayedUpLate"
    }

    static var wakeOnTimeItemIdentifier: String {
        "\(identifier()).form.wakeOnTime"
    }

    static var sleepQualityItemIdentifier: String {
        "\(identifier()).form.sleepQuality"
    }
}

#if canImport(ResearchKit)
extension CheckIn {
    func createSurvey() -> ORKTask {
        let sleepAnswerFormat = ORKAnswerFormat.scale(
            withMaximumValue: 12,
            minimumValue: 0,
            defaultValue: 0,
            step: 1,
            vertical: false,
            maximumValueDescription: nil,
            minimumValueDescription: nil
        )

        let sleepItem = ORKFormItem(
            identifier: Self.sleepItemIdentifier,
            text: "How many hours of sleep did you get last night?",
            answerFormat: sleepAnswerFormat
        )
        sleepItem.isOptional = false

        let stayedUpLateItem = ORKFormItem(
            identifier: Self.stayedUpLateItemIdentifier,
            text: "Did you stay up late last night?",
            answerFormat: ORKBooleanAnswerFormat()
        )
        stayedUpLateItem.isOptional = false

        let wakeOnTimeItem = ORKFormItem(
            identifier: Self.wakeOnTimeItemIdentifier,
            text: "Did you wake when you intended to?",
            answerFormat: ORKBooleanAnswerFormat()
        )
        wakeOnTimeItem.isOptional = false

        let sleepQualityItem = ORKFormItem(
            identifier: Self.sleepQualityItemIdentifier,
            text: "How would you rate the quality of your sleep?",
            answerFormat: ORKScaleAnswerFormat(
                maximumValue: 10,
                minimumValue: 0,
                defaultValue: 0,
                step: 1,
                vertical: false,
                maximumValueDescription: "Great",
                minimumValueDescription: "Awful"
            )
        )
        sleepQualityItem.isOptional = false

        let formStep = ORKFormStep(
            identifier: Self.formIdentifier,
            title: "Check In",
            text: "Please answer the following questions."
        )
        formStep.formItems = [sleepItem, stayedUpLateItem, wakeOnTimeItem, sleepQualityItem]
        formStep.isOptional = false

        let surveyTask = ORKOrderedTask(
            identifier: identifier(),
            steps: [formStep]
        )
        return surveyTask
    }

    func extractAnswers(_ result: ORKTaskResult) -> [OCKOutcomeValue]? {
        guard
            let response = result.results?
            .compactMap({ $0 as? ORKStepResult })
            .first(where: { $0.identifier == Self.formIdentifier }),

            let scaleResults = response
            .results?.compactMap({ $0 as? ORKScaleQuestionResult }),

            let sleepAnswer = scaleResults
            .first(where: { $0.identifier == Self.sleepItemIdentifier })?
            .scaleAnswer,

            let sleepQualityAnswer = scaleResults
            .first(where: { $0.identifier == Self.sleepQualityItemIdentifier })?
            .scaleAnswer,

            let stayedUpLateAnswer = response
            .results?.compactMap({ $0 as? ORKBooleanQuestionResult })
            .first(where: { $0.identifier == Self.stayedUpLateItemIdentifier })?
            .booleanAnswer,

            let wakeOnTimeAnswer = response
            .results?.compactMap({ $0 as? ORKBooleanQuestionResult })
            .first(where: { $0.identifier == Self.wakeOnTimeItemIdentifier })?
            .booleanAnswer
        else {
            assertionFailure("Failed to extract answers from check in survey!")
            return nil
        }

        var sleepValue = OCKOutcomeValue(Double(truncating: sleepAnswer))
        sleepValue.kind = Self.sleepItemIdentifier

        var sleepQualityValue = OCKOutcomeValue(Double(truncating: sleepQualityAnswer))
        sleepQualityValue.kind = Self.sleepQualityItemIdentifier

        var stayedUpLateValue = OCKOutcomeValue(stayedUpLateAnswer.boolValue)
        stayedUpLateValue.kind = Self.stayedUpLateItemIdentifier

        var wakeOnTimeValue = OCKOutcomeValue(wakeOnTimeAnswer.boolValue)
        wakeOnTimeValue.kind = Self.wakeOnTimeItemIdentifier

        return [sleepValue, sleepQualityValue, stayedUpLateValue, wakeOnTimeValue]
    }
}
#endif
