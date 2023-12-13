//
//  Profile.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import CareKitUtilities
import os.log
import ParseSwift
import SwiftUI

// swiftlint:disable type_body_length
class ProfileViewModel: ObservableObject {
    // MARK: Public read/write properties

    @Published var firstName = ""
    @Published var lastName = ""
    @Published var birthday = Date()
    @Published var sex: OCKBiologicalSex = .other("other")
    @Published var sexOtherField = "other"
    @Published var allergies = ""
    @Published var note = ""
    @Published var street = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zipcode = ""
    @Published var email = ""
    @Published var messagingNumber = ""
    @Published var phoneNumber = ""
    @Published var otherContactInfo = ""
    @Published var isShowingSaveAlert = false
    @Published var isPresentingAddTask = false
    @Published var isPresentingContact = false
    @Published var isPresentingImagePicker = false
    @Published var profileUIImage = UIImage(systemName: "person.fill") {
        willSet {
            guard profileUIImage != newValue,
                  let inputImage = newValue
            else {
                return
            }

            if !isSettingProfilePictureForFirstTime {
                Task {
                    guard var currentUser = (try? await User.current()),
                          let image = inputImage.jpegData(compressionQuality: 0.25)
                    else {
                        Logger.profile.error("User is not logged in or could not compress image")
                        return
                    }

                    let newProfilePicture = ParseFile(name: "profile.jpg", data: image)
                    // Use `.set()` to update ParseObject's that have already been saved before.
                    currentUser = currentUser.set(\.profilePicture, to: newProfilePicture)
                    do {
                        _ = try await currentUser.save()
                        Logger.profile.info("Saved updated profile picture successfully.")
                    } catch {
                        Logger.profile.error("Could not save profile picture: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    @Published private(set) var error: Error?
    private(set) var alertMessage = "All changs saved successfully!"
    private var contact: OCKContact? {
        willSet {
            if let name = newValue?.name {
                if let newFirstName = name.givenName {
                    firstName = newFirstName
                } else {
                    firstName = ""
                }
                if let newLastName = name.familyName {
                    lastName = newLastName
                } else {
                    lastName = ""
                }
            } else {
                firstName = ""
                lastName = ""
            }
            if let currentStreet = newValue?.address?.street {
                street = currentStreet
            } else {
                street = ""
            }
            if let currentCity = newValue?.address?.city {
                city = currentCity
            } else {
                city = ""
            }
            if let currentState = newValue?.address?.state {
                state = currentState
            } else {
                state = ""
            }
            if let currentZipcode = newValue?.address?.postalCode {
                zipcode = currentZipcode
            } else {
                zipcode = ""
            }
            if let currentNote = newValue?.notes?.first?.content {
                note = currentNote
            } else {
                note = ""
            }
            if let currentEmail = newValue?.emailAddresses?.first?.value {
                email = currentEmail
            } else {
                email = ""
            }
            if let currentMessagingNumbers = newValue?.messagingNumbers?.first?.value {
                messagingNumber = currentMessagingNumbers
            } else {
                messagingNumber = ""
            }
            if let currentPhoneNumbers = newValue?.phoneNumbers?.first?.value {
                phoneNumber = currentPhoneNumbers
            } else {
                phoneNumber = ""
            }
            if let currentOtherContactInfo = newValue?.otherContactInfo?.first?.value {
                otherContactInfo = currentOtherContactInfo
            } else {
                otherContactInfo = ""
            }
        }
    }

    // MARK: Private read/write properties

    private var isSettingProfilePictureForFirstTime = true

    var patient: OCKPatient? {
        willSet {
            if let currentFirstName = newValue?.name.givenName {
                firstName = currentFirstName
            } else {
                firstName = ""
            }
            if let currentLastName = newValue?.name.familyName {
                lastName = currentLastName
            } else {
                lastName = ""
            }
            if let currentBirthday = newValue?.birthday {
                birthday = currentBirthday
            } else {
                birthday = Date()
            }
            if let allergies = newValue?.allergies?.first {
                self.allergies = allergies
            } else {
                allergies = ""
            }
        }
    }

    // MARK: Helpers (public)

    func updatePatient(_ patient: OCKAnyPatient) {
        guard let patient = patient as? OCKPatient,
              // Only update if we have a newer version.
              patient.uuid != self.patient?.uuid
        else {
            return
        }
        self.patient = patient

        // Fetch the profile picture if we have a patient.
        Task {
            try await fetchProfilePicture()
        }
    }

    func updateContact(_ contact: OCKAnyContact) {
        guard let currentPatient = patient,
              let contact = contact as? OCKContact,
              // Has to be my contact.
              contact.id == currentPatient.id,
              // Only update if we have a newer version.
              contact.uuid != self.contact?.uuid
        else {
            return
        }
        self.contact = contact
    }

    @MainActor
    private func fetchProfilePicture() async throws {
        // Profile pics are stored in Parse User.
        guard let currentUser = (try? await User.current().fetch()) else {
            Logger.profile.error("User is not logged in")
            return
        }

        if let pictureFile = currentUser.profilePicture {
            // Download picture from server if needed
            do {
                let profilePicture = try await pictureFile.fetch()
                guard let path = profilePicture.localURL?.relativePath else {
                    Logger.profile.error("Could not find relative path for profile picture.")
                    return
                }
                profileUIImage = UIImage(contentsOfFile: path)
            } catch {
                Logger.profile.error("Could not fetch profile picture: \(error.localizedDescription).")
            }
        }
        isSettingProfilePictureForFirstTime = false
    }

    // MARK: User intentional behavior

    @MainActor
    func saveProfile() async {
        alertMessage = "All changs saved successfully!"
        do {
            try await savePatient()
            try await saveContact()
        } catch {
            alertMessage = "Could not save profile: \(error)"
        }
        isShowingSaveAlert = true // Make alert pop up for user.
    }

    @MainActor
    func savePatient() async throws {
        if var patientToUpdate = patient {
            // If there is a currentPatient that was fetched, check to see if any of the fields changed
            Logger.profile.info("Updating patient...")

            var patientHasBeenUpdated = false

            if patient?.name.givenName != firstName {
                patientHasBeenUpdated = true
                patientToUpdate.name.givenName = firstName
            }

            if patient?.name.familyName != lastName {
                patientHasBeenUpdated = true
                patientToUpdate.name.familyName = lastName
            }

            if patient?.birthday != birthday {
                patientHasBeenUpdated = true
                patientToUpdate.birthday = birthday
            }

            if patient?.sex != sex {
                patientHasBeenUpdated = true
                patientToUpdate.sex = sex
            }

            if patient?.allergies?.first != allergies {
                patientHasBeenUpdated = true
                patientToUpdate.allergies = [allergies]
            }

            if patient?.notes?.first?.content != note {
                patientHasBeenUpdated = true
                patientToUpdate.notes = [OCKNote(author: firstName,
                                                 title: "New Note",
                                                 content: note)]
            }

            if patientHasBeenUpdated {
                _ = try await AppDelegateKey.defaultValue?.store.updateAnyPatient(patientToUpdate)
                Logger.profile.info("Successfully updated patient")
            }
        } else {
            guard let remoteUUID = (try? await Utility.getRemoteClockUUID())?.uuidString else {
                Logger.profile.error("The user currently is not logged in")
                return
            }
            let newPatient = OCKPatient(id: remoteUUID,
                                        givenName: firstName,
                                        familyName: lastName)
            _ = try await AppDelegateKey.defaultValue?.store.addAnyPatient(newPatient)
            Logger.profile.info("Created new patient")
        }
    }

    @MainActor
    // swiftlint:disable:next cyclomatic_complexity
    func saveContact() async throws {
        if var contactToUpdate = contact {
            Logger.profile.info("Updating contact...")
            // If a current contact was fetched, check to see if any of the fields have changed
            var contactHasBeenUpdated = false

            // Since OCKPatient was updated earlier, we should compare against this name
            if let patientName = patient?.name,
               contact?.name != patient?.name {
                contactHasBeenUpdated = true
                contactToUpdate.name = patientName
            }

            // Create a mutable temp address to compare
            let potentialAddress = OCKPostalAddress()
            potentialAddress.street = street
            potentialAddress.city = city
            potentialAddress.state = state
            potentialAddress.postalCode = zipcode

            if contact?.address != potentialAddress {
                contactHasBeenUpdated = true
                contactToUpdate.address = potentialAddress
            }

            if contact?.messagingNumbers?.first?.value != phoneNumber {
                contactHasBeenUpdated = true
                contactToUpdate.messagingNumbers = [OCKLabeledValue(label: "phone", value: phoneNumber)]
            }

            if contact?.phoneNumbers?.first?.value != phoneNumber {
                contactHasBeenUpdated = true
                contactToUpdate.phoneNumbers = [OCKLabeledValue(label: "phone", value: phoneNumber)]
            }

            if contact?.emailAddresses?.first?.value != email {
                contactHasBeenUpdated = true
                contactToUpdate.emailAddresses = [OCKLabeledValue(label: "email", value: email)]
            }

            if contact?.otherContactInfo?.first?.value != otherContactInfo {
                contactHasBeenUpdated = true
                contactToUpdate.otherContactInfo = [OCKLabeledValue(label: "other", value: otherContactInfo)]
            }

            if contact?.notes?.first?.content != note {
                contactHasBeenUpdated = true
                contactToUpdate.notes = [OCKNote](arrayLiteral: OCKNote(author: firstName,
                                                                        title: "New Note",
                                                                        content: note))
            }

            if contactHasBeenUpdated {
                _ = try await AppDelegateKey.defaultValue?.store.updateAnyContact(contactToUpdate)
                Logger.profile.info("Successfully updated contact")
            }

        } else {
            guard let remoteUUID = (try? await Utility.getRemoteClockUUID())?.uuidString else {
                Logger.profile.error("The user currently is not logged in")
                return
            }

            guard let patientName = patient?.name else {
                Logger.profile.info("The patient did not have a name.")
                return
            }

            Logger.profile.info("Saving new contact...")

            // Added code to create a contact for the respective signed up user
            let newContact = OCKContact(id: remoteUUID,
                                        name: patientName,
                                        carePlanUUID: nil)

            _ = try await AppDelegateKey.defaultValue?.store.addAnyContact(newContact)
            Logger.profile.info("Succesffully saved new contact")
        }
    }

    static func queryPatient() -> OCKPatientQuery {
        OCKPatientQuery(for: Date())
    }

    static func queryContacts() -> OCKContactQuery {
        OCKContactQuery(for: Date())
    }
}
