//
//  ProfileView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import CareKitUI
import os.log
import SwiftUI

struct ProfileView: View {
    private static var query = OCKPatientQuery(for: Date())
    @CareStoreFetchRequest(query: query) private var patients
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject var loginViewModel: LoginViewModel
    @State var shouldShowAddTask = false

    var body: some View {
        NavigationView {
            VStack {
                VStack(alignment: .leading) {
                    TextField("First Name",
                              text: $viewModel.firstName)
                        .padding()
                        .cornerRadius(20.0)
                        .shadow(radius: 10.0, x: 20, y: 10)

                    TextField("Last Name",
                              text: $viewModel.lastName)
                        .padding()
                        .cornerRadius(20.0)
                        .shadow(radius: 10.0, x: 20, y: 10)

                    DatePicker("Birthday",
                               selection: $viewModel.birthday,
                               displayedComponents: [DatePickerComponents.date])
                        .padding()
                        .cornerRadius(20.0)
                        .shadow(radius: 10.0, x: 20, y: 10)
                }

                Button(action: {
                    Task {
                        do {
                            try await viewModel.saveProfile()
                        } catch {
                            Logger.profile.error("Error saving profile: \(error)")
                        }
                    }
                }, label: {
                    Text("Save Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 50)
                })
                .background(Color(.green))
                .cornerRadius(15)

                Button(action: {
                    Task {
                        await loginViewModel.logout()
                    }
                }, label: {
                    Text("Log Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 50)
                })
                .background(Color(.red))
                .cornerRadius(15)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Task") {
                        shouldShowAddTask = true
                    }
                    .sheet(isPresented: $shouldShowAddTask) {
                        CareKitTaskView()
                    }
                }
            }
        }
        .onReceive(patients.publisher) { publishedPatient in
            viewModel.updatePatient(publishedPatient.result)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(loginViewModel: .init())
            .accentColor(Color(TintColorKey.defaultValue))
            .environment(\.careStore, Utility.createPreviewStore())
    }
}
