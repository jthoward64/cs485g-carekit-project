//
//  CareView.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 6/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import CareKitUI
import os.log
import SwiftUI

struct CareView: View {
    private static var query: OCKEventQuery {
        var query = OCKEventQuery(for: Date())
        query.taskIDs = [TaskID.getUp, TaskID.breakfast]
        return query
    }

    @CareStoreFetchRequest(query: query) private var events

    var body: some View {
        ScrollView {
            ForEach(events) { event in
                if event.result.task.id == TaskID.breakfast {
                    SimpleTaskView(event: event)
                } else if event.result.task.id == TaskID.getUp {
                    InstructionsTaskView(event: event)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CareView()
            .accentColor(Color(TintColorKey.defaultValue))
            .environment(\.careStore, Utility.createPreviewStore())
    }
}
