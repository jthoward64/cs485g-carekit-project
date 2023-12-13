//
//  CareKitTaskView.swift
//  OCKSample
//
//  Created by Joshua Howard on 12/12/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI

struct CareKitTaskView: View {
    // MARK: Navigation

    @State var isShowingAlert = false
    @State var isAddingTask = false

    // MARK: View

    @StateObject var viewModel = CareKitTaskViewModel()
    @State var title = ""
    @State var instructions = ""
    @State var cardType: CareKitCard = .button

    var body: some View {
        NavigationView {
            VStack {
                Text("Add a Task")
                Form {
                    TextField("Task Title",
                              text: $title)
                    TextField("Instructions",
                              text: $instructions)
                    Picker("Card View", selection: $cardType) {
                        ForEach(CareKitCard.allCases) { item in
                            Text(item.rawValue)
                        }
                    }
                    Section("Normal Task") {
                        Button("Add") {
                            addTask {
                                await viewModel.addTask(
                                    title,
                                    instructions: instructions,
                                    cardType: cardType
                                )
                            }
                        }.alert(
                            "Task added",
                            isPresented: $isShowingAlert
                        ) {
                            Button("OK") {
                                isShowingAlert = false
                            }
                        }.disabled(isAddingTask)
                    }
                    Section("HealthKit Task") {
                        Button("Add") {
                            addTask {
                                await viewModel.addHealthKitTask(
                                    title,
                                    instructions: instructions,
                                    cardType: cardType
                                )
                            }
                        }.alert(
                            "HealthKitTask added",
                            isPresented: $isShowingAlert
                        ) {
                            Button("OK") {
                                isShowingAlert = false
                            }
                        }.disabled(isAddingTask)
                    }
                }
            }
        }
    }

    // MARK: Helpers

    func addTask(_ task: @escaping (() async -> Void)) {
        isAddingTask = true
        Task {
            await task()
            isAddingTask = false
            isShowingAlert = true
        }
    }
}

#Preview {
    CareKitTaskView()
}
