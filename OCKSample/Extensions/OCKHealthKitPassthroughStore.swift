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

    /*
      TODO: You need to tie an OCPatient and CarePlan to these tasks,
     */
    func populateSampleData(_ patientUUID: UUID? = nil) async throws {
        let store = OCKStore(name: Constants.noCareStoreName, type: .inMemory)
        let insomniaCarePlan = try await store.fetchCarePlan(withID: CarePlanID.insomnia.rawValue)

        let schedule = OCKSchedule.dailyAtTime(
            hour: 8, minutes: 0, start: Date(), end: nil, text: nil, targetValues: [OCKOutcomeValue(65, units: "F")])

        var steps = OCKHealthKitTask(
            id: TaskID.sleepTemp,
            title: "Sleep Temperature",
            carePlanUUID: insomniaCarePlan.uuid,
            schedule: schedule,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .appleSleepingWristTemperature,
                quantityType: .discrete,
                unit: .count()))
        steps.asset = "medical.thermometer"
        steps.instructions = "Your sleeping temperature should be between 60-67 degrees Fahrenheit."
        steps.card = .labeledValueTask
        try await addTasksIfNotPresent([steps])
    }
}
