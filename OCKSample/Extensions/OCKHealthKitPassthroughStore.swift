//
//  OCKHealthKitPassthroughStore.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Foundation
import HealthKit
import os.log

extension OCKHealthKitPassthroughStore {
    func addTasksIfNotPresent(_ tasks: [OCKHealthKitTask]) async throws {
        let tasksToAdd = tasks
        let taskIdsToAdd = tasksToAdd.compactMap { $0.id }

        // Prepare query to see if tasks are already added
        var query = OCKTaskQuery(for: Date())
        query.ids = taskIdsToAdd

        let foundTasks = try await fetchTasks(query: query)
        var tasksNotInStore = [OCKHealthKitTask]()

        // Check results to see if there's a missing task
        tasksToAdd.forEach { potentialTask in
            if foundTasks.first(where: { $0.id == potentialTask.id }) == nil {
                tasksNotInStore.append(potentialTask)
            }
        }

        // Only add if there's a new task
        if tasksNotInStore.count > 0 {
            do {
                _ = try await addTasks(tasksNotInStore)
                Logger.ockHealthKitPassthroughStore.info("Added tasks into HealthKitPassthroughStore!")
            } catch {
                Logger.ockHealthKitPassthroughStore.error("Error adding HealthKitTasks: \(error)")
            }
        }
    }

    func populateSampleData(_ patientUUID: UUID? = nil) async throws {
        let everyNight = OCKSchedule.dailyAtTime(
            // swiftlint:disable:next line_length
            hour: 20, minutes: 0, start: Date(), end: nil, text: nil, duration: OCKScheduleElement.Duration.hours(10), targetValues: [OCKOutcomeValue(65, units: "F")])

        let walkEveryMorning = OCKSchedule.dailyAtTime(
            // swiftlint:disable:next line_length
            hour: 8, minutes: 0, start: Date(), end: nil, text: nil, duration: .hours(2), targetValues: [OCKOutcomeValue(500, units: "steps")])

        let getUpEveryMorning = OCKSchedule.dailyAtTime(
            // swiftlint:disable:next line_length
            hour: 8, minutes: 0, start: Date(), end: nil, text: nil, duration: .hours(1), targetValues: [OCKOutcomeValue(30, units: "minutes")])

        /*
         This is a type method as it is not called on an instance of OCKStore but rather the type itself
         An instance method would be if it were called on something like `AppDelegateKey.defaultValue?.store`
         */
        let carePlans = try await OCKStore.getCarePlanUUIDs()

        var sleepTemp = OCKHealthKitTask(
            id: TaskID.sleepTemp,
            title: "Sleep Temperature",

            carePlanUUID: carePlans[CarePlanID.insomnia],
            schedule: everyNight,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .appleSleepingWristTemperature,
                quantityType: .discrete,
                unit: .degreeFahrenheit()))
        sleepTemp.asset = "medical.thermometer"
        sleepTemp.instructions = "Your sleeping temperature should be between 60-67 degrees Fahrenheit."
        sleepTemp.card = .labeledValueTask

        var morningWalk = OCKHealthKitTask(
            id: TaskID.morningWalk,
            title: "Take a Walk",
            carePlanUUID: carePlans[CarePlanID.sleepingIn],
            schedule: walkEveryMorning,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .appleSleepingWristTemperature,
                quantityType: .discrete,
                unit: .count()))
        morningWalk.asset = "figure.walk"
        morningWalk.instructions = "Take a short walk to get your blood flowing!"
        morningWalk.card = .numericProgress

        var getUp = OCKHealthKitTask(
            id: TaskID.morningWalk,
            title: "Get out of bed",
            carePlanUUID: carePlans[CarePlanID.sleepingIn],
            schedule: getUpEveryMorning,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .appleStandTime,
                quantityType: .cumulative,
                unit: .minute()))
        getUp.asset = "figure"
        getUp.instructions = "How long were you out of bed this morning?"
        getUp.card = .labeledValueTask

        try await addTasksIfNotPresent([sleepTemp])
    }
}
