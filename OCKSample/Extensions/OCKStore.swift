//
//  OCKStore.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Contacts
import Foundation
import os.log
import ParseCareKit
import ParseSwift

extension OCKStore {
    @MainActor
    class func getCarePlanUUIDs() async throws -> [CarePlanID: UUID] {
        var results = [CarePlanID: UUID]()

        guard let store = AppDelegateKey.defaultValue?.store else {
            return results
        }

        var query = OCKCarePlanQuery(for: Date())
        query.ids = [CarePlanID.health.rawValue,
                     CarePlanID.checkIn.rawValue]

        let foundCarePlans = try await store.fetchCarePlans(query: query)
        // Populate the dictionary for all CarePlan's
        CarePlanID.allCases.forEach { carePlanID in
            results[carePlanID] = foundCarePlans
                .first(where: { $0.id == carePlanID.rawValue })?.uuid
        }
        return results
    }

    /**
      Adds an `OCKAnyCarePlan`*asynchronously*  to `OCKStore` if it has not been added already.
      - parameter carePlans: The array of `OCKAnyCarePlan`'s to be added to the `OCKStore`.
      - parameter patientUUID: The uuid of the `OCKPatient` to tie to the `OCKCarePlan`. Defaults to nil.
      - throws: An error if there was a problem adding the missing `OCKAnyCarePlan`'s.
      - note: `OCKAnyCarePlan`'s that have an existing `id` will not be added and will not cause errors to be thrown.
     */
    func addCarePlansIfNotPresent(_ carePlans: [OCKAnyCarePlan], patientUUID: UUID? = nil) async throws {
        let carePlanIdsToAdd = carePlans.compactMap { $0.id }

        // Prepare query to see if Care Plan are already added
        var query = OCKCarePlanQuery(for: Date())
        query.ids = carePlanIdsToAdd
        let foundCarePlans = try await fetchAnyCarePlans(query: query)
        var carePlanNotInStore = [OCKAnyCarePlan]()
        // Check results to see if there's a missing Care Plan
        carePlans.forEach { potentialCarePlan in
            if foundCarePlans.first(where: { $0.id == potentialCarePlan.id }) == nil {
                // Check if can be casted to OCKCarePlan to add patientUUID
                guard var mutableCarePlan = potentialCarePlan as? OCKCarePlan else {
                    carePlanNotInStore.append(potentialCarePlan)
                    return
                }
                mutableCarePlan.patientUUID = patientUUID
                carePlanNotInStore.append(mutableCarePlan)
            }
        }

        // Only add if there's a new Care Plan
        if carePlanNotInStore.count > 0 {
            do {
                _ = try await addAnyCarePlans(carePlanNotInStore)
                Logger.ockStore.info("Added Care Plans into OCKStore!")
            } catch {
                Logger.ockStore.error("Error adding Care Plans: \(error.localizedDescription)")
            }
        }
    }

    func addTasksIfNotPresent(_ tasks: [OCKTask]) async throws {
        let taskIdsToAdd = tasks.compactMap { $0.id }

        // Prepare query to see if tasks are already added
        var query = OCKTaskQuery(for: Date())
        query.ids = taskIdsToAdd

        let foundTasks = try await fetchTasks(query: query)
        var tasksNotInStore = [OCKTask]()

        // Check results to see if there's a missing task
        tasks.forEach { potentialTask in
            if foundTasks.first(where: { $0.id == potentialTask.id }) == nil {
                tasksNotInStore.append(potentialTask)
            }
        }

        // Only add if there's a new task
        if tasksNotInStore.count > 0 {
            do {
                _ = try await addTasks(tasksNotInStore)
                Logger.ockStore.info("Added tasks into OCKStore!")
            } catch {
                Logger.ockStore.error("Error adding tasks: \(error)")
            }
        }
    }

    func addContactsIfNotPresent(_ contacts: [OCKContact]) async throws {
        let contactIdsToAdd = contacts.compactMap { $0.id }

        // Prepare query to see if contacts are already added
        var query = OCKContactQuery(for: Date())
        query.ids = contactIdsToAdd

        let foundContacts = try await fetchContacts(query: query)
        var contactsNotInStore = [OCKContact]()

        // Check results to see if there's a missing task
        contacts.forEach { potential in
            if foundContacts.first(where: { $0.id == potential.id }) == nil {
                contactsNotInStore.append(potential)
            }
        }

        // Only add if there's a new task
        if contactsNotInStore.count > 0 {
            do {
                _ = try await addContacts(contactsNotInStore)
                Logger.ockStore.info("Added contacts into OCKStore!")
            } catch {
                Logger.ockStore.error("Error adding contacts: \(error)")
            }
        }
    }

    func populateCarePlans(patientUUID: UUID? = nil) async throws {
        let checkInCarePlan = OCKCarePlan(id: CarePlanID.checkIn.rawValue,
                                          title: "Check in Care Plan",
                                          patientUUID: patientUUID)
        let insomniaCarePlan = OCKCarePlan(id: CarePlanID.insomnia.rawValue,
                                           title: "Insomnia Care Plan",
                                           patientUUID: patientUUID)
        let sleepingInCarePlan = OCKCarePlan(id: CarePlanID.sleepingIn.rawValue,
                                             title: "Sleeping in Care Plan",
                                             patientUUID: patientUUID)
        try await addCarePlansIfNotPresent([checkInCarePlan, insomniaCarePlan, sleepingInCarePlan],
                                           patientUUID: patientUUID)
    }

    // Adds tasks and contacts into the store
    func populateSampleData(_ patientUUID: UUID? = nil) async throws {
        try await populateCarePlans(patientUUID: patientUUID)

        let thisMorning = Calendar.current.startOfDay(for: Date())
        guard let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning),
              let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo),
//              let afterBreakfast = Calendar.current.date(byAdding: .hour, value: 9, to: aFewDaysAgo),
              let afterLunch = Calendar.current.date(byAdding: .hour, value: 14, to: aFewDaysAgo)
        else {
            Logger.ockStore.error("Could not unwrap calendar. Should never hit")
            throw AppError.couldntBeUnwrapped
        }

        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast,
                               end: nil,
                               interval: DateComponents(day: 1)),

            OCKScheduleElement(start: afterLunch,
                               end: nil,
                               interval: DateComponents(day: 2))
        ])

        let carePlans = try await OCKStore.getCarePlanUUIDs()
        let insomniaCarePlan = carePlans[CarePlanID.insomnia]
        let sleepingInCarePlan = carePlans[CarePlanID.sleepingIn]

        var sleepingPills = OCKTask(id: TaskID.sleepingPill,
                                    title: "Take sleeping pill",
                                    carePlanUUID: insomniaCarePlan,
                                    schedule: schedule)
        sleepingPills.instructions = "Take a sleeping tablet when having touble sleeping"
        sleepingPills.asset = "pills.fill"
        sleepingPills.card = .checklist

        let insomniaSchedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast,
                               end: nil,
                               interval: DateComponents(day: 1),
                               text: "Anytime throughout the day",
                               targetValues: [], duration: .allDay)
        ])

        var cantSleep = OCKTask(id: TaskID.cantSleep,
                                title: "Track your insomnia",
                                carePlanUUID: insomniaCarePlan,
                                schedule: insomniaSchedule)
        cantSleep.impactsAdherence = false
        cantSleep.instructions = "Tap the button below anytime you have trouble sleeping."
        cantSleep.asset = "bell.fill"
        cantSleep.card = .button

        let breakfastElement = OCKScheduleElement(start: beforeBreakfast,
                                                  end: nil,
                                                  interval: DateComponents(day: 2))
        let breakfastSchedule = OCKSchedule(composing: [breakfastElement])
        var breakfast = OCKTask(id: TaskID.breakfast,
                                title: "Have a healthy breakfast",
                                carePlanUUID: sleepingInCarePlan,
                                schedule: breakfastSchedule)
        breakfast.impactsAdherence = true
        breakfast.instructions = "Have a healthy breakfast"
        breakfast.card = .simpleTask

        let linkElement = OCKScheduleElement(start: afterLunch, end: nil, interval: DateComponents(day: 7))
        let linkSchedule = OCKSchedule(composing: [linkElement])
        var link = OCKTask(id: TaskID.link,
                           title: "Sleep is cool!",
                           carePlanUUID: carePlans[.checkIn],
                           schedule: linkSchedule)
        link.impactsAdherence = false
        link.card = .link

        let reflectElement = OCKScheduleElement(start: afterLunch, end: nil, interval: DateComponents(month: 1))
        let reflectSchedule = OCKSchedule(composing: [reflectElement])
        var reflect = OCKTask(id: TaskID.reflect,
                              title: "Reflect on your sleep patterns",
                              carePlanUUID: carePlans[.checkIn],
                              schedule: reflectSchedule)
        reflect.impactsAdherence = false
        reflect.instructions = "Consider any outside factors that may have affected your sleep patterns. " +
            "Is there anything you can do to improve your sleep?"
        reflect.asset = "lightbulb.fill"
        reflect.card = .instructionsTask

//        let getUpElement = OCKScheduleElement(start: afterBreakfast,
//                                              end: nil,
//                                              interval: DateComponents(day: 1))
//        let stretchSchedule = OCKSchedule(composing: [getUpElement])
//        var getUp = OCKTask(id: TaskID.getUp,
//                            title: "Get out and about",
//                            carePlanUUID: sleepingInCarePlan.uuid,
//                            schedule: stretchSchedule)
//        getUp.impactsAdherence = true
//        getUp.asset = "figure.walk"
//        getUp.instructions = "Moving around in the morning can help you train your brain to " +
//            "transition to and from sleep."
//        getUp.card = .instructionsTask

        let carePlanUUIDs = try await Self.getCarePlanUUIDs()
        try await addTasksIfNotPresent([breakfast, cantSleep, reflect, sleepingPills, link])
        try await addOnboardingTask(carePlanUUIDs[.health])
        try await addSurveyTasks(carePlanUUIDs[.checkIn])

        var contact1 = OCKContact(id: "jane",
                                  givenName: "Jane",
                                  familyName: "Daniels",
                                  carePlanUUID: nil)
        contact1.asset = "JaneDaniels"
        contact1.title = "Family Practice Doctor"
        contact1.role = "Dr. Daniels is a family practice doctor with 8 years of experience."
        contact1.emailAddresses = [OCKLabeledValue(label: CNLabelEmailiCloud, value: "janedaniels@uky.edu")]
        contact1.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(859) 257-2000")]
        contact1.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(859) 357-2040")]

        contact1.address = {
            let address = OCKPostalAddress()
            address.street = "2195 Harrodsburg Rd"
            address.city = "Lexington"
            address.state = "KY"
            address.postalCode = "40504"
            return address
        }()

        var contact2 = OCKContact(id: "matthew", givenName: "Matthew",
                                  familyName: "Reiff", carePlanUUID: nil)
        contact2.asset = "MatthewReiff"
        contact2.title = "OBGYN"
        contact2.role = "Dr. Reiff is an OBGYN with 13 years of experience."
        contact2.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(859) 257-1000")]
        contact2.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(859) 257-1234")]
        contact2.address = {
            let address = OCKPostalAddress()
            address.street = "1000 S Limestone"
            address.city = "Lexington"
            address.state = "KY"
            address.postalCode = "40536"
            return address
        }()

        try await addContactsIfNotPresent([contact1, contact2])
    }

    func addOnboardingTask(_ carePlanUUID: UUID? = nil) async throws {
        let onboardSchedule = OCKSchedule.dailyAtTime(
            hour: 0, minutes: 0,
            start: Date(), end: nil,
            text: "Task Due!",
            duration: .allDay
        )

        var onboardTask = OCKTask(
            id: Onboard.identifier(),
            title: "Onboard",
            carePlanUUID: carePlanUUID,
            schedule: onboardSchedule
        )
        onboardTask.instructions = "You'll need to agree to some terms and conditions before we get started!"
        onboardTask.impactsAdherence = false
        onboardTask.card = .survey
        onboardTask.survey = .onboard

        try await addTasksIfNotPresent([onboardTask])
    }

    func addSurveyTasks(_ carePlanUUID: UUID? = nil) async throws {
        let checkInSchedule = OCKSchedule.dailyAtTime(
            hour: 8, minutes: 0,
            start: Date(), end: nil,
            text: nil
        )

        var checkInTask = OCKTask(
            id: CheckIn.identifier(),
            title: "Check In",
            carePlanUUID: carePlanUUID,
            schedule: checkInSchedule
        )
        checkInTask.card = .survey
        checkInTask.survey = .checkIn

        let thisMorning = Calendar.current.startOfDay(for: Date())

        let nextWeek = Calendar.current.date(
            byAdding: .weekOfYear,
            value: 1,
            to: Date()
        )!

        let nextMonth = Calendar.current.date(
            byAdding: .month,
            value: 1,
            to: thisMorning
        )

        let dailyElement = OCKScheduleElement(
            start: thisMorning,
            end: nextWeek,
            interval: DateComponents(day: 1),
            text: nil,
            targetValues: [],
            duration: .allDay
        )

        let weeklyElement = OCKScheduleElement(
            start: nextWeek,
            end: nextMonth,
            interval: DateComponents(weekOfYear: 1),
            text: nil,
            targetValues: [],
            duration: .allDay
        )

        let rangeOfMotionCheckSchedule = OCKSchedule(
            composing: [dailyElement, weeklyElement]
        )

        var rangeOfMotionTask = OCKTask(
            id: RangeOfMotion.identifier(),
            title: "Range Of Motion",
            carePlanUUID: carePlanUUID,
            schedule: rangeOfMotionCheckSchedule
        )
        rangeOfMotionTask.card = .survey
        rangeOfMotionTask.survey = .rangeOfMotion

        try await addTasksIfNotPresent([checkInTask, rangeOfMotionTask])
    }
}
