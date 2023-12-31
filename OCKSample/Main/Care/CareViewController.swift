/*
 Copyright (c) 2019, Apple Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import CareKit
import CareKitStore
import CareKitUI
import os.log
import ResearchKit
import SwiftUI
import UIKit

// swiftlint:disable type_body_length
@MainActor
class CareViewController: OCKDailyPageViewController {
    private var isSyncing = false
    private var isLoading = false
    var events: CareStoreFetchedResults<OCKAnyEvent, OCKEventQuery>? {
        didSet {
            reloadView()
        }
    }

    /// Create an instance of the view controller. Will hook up the calendar to the tasks collection,
    /// and query and display the tasks.
    ///
    /// - Parameter store: The store from which to query the tasks.
    /// - Parameter computeProgress: Used to compute the combined progress for a series of CareKit events.
    init(store: OCKAnyStoreProtocol,
         events: CareStoreFetchedResults<OCKAnyEvent, OCKEventQuery>? = nil,
         computeProgress: @escaping (OCKAnyEvent) -> CareTaskProgress = { event in
             event.computeProgress(by: .checkingOutcomeExists)
         }) {
        super.init(store: store, computeProgress: computeProgress)
        self.events = events
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh,
                                                            target: self,
                                                            action: #selector(synchronizeWithRemote))
        NotificationCenter.default.addObserver(self, selector: #selector(synchronizeWithRemote),
                                               name: Notification.Name(rawValue: Constants.requestSync),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateSynchronizationProgress(_:)),
                                               name: Notification.Name(rawValue: Constants.progressUpdate),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadView(_:)),
                                               name: Notification.Name(rawValue: Constants.finishedAskingForPermission),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadView(_:)),
                                               name: Notification.Name(rawValue: Constants.shouldRefreshView),
                                               object: nil)
    }

    @objc private func updateSynchronizationProgress(_ notification: Notification) {
        guard let receivedInfo = notification.userInfo as? [String: Any],
              let progress = receivedInfo[Constants.progressUpdate] as? Int
        else {
            return
        }

        DispatchQueue.main.async {
            switch progress {
            case 0, 100:
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "\(progress)",
                                                                         style: .plain, target: self,
                                                                         action: #selector(self.synchronizeWithRemote))
                if progress == 100 {
                    // Give sometime for the user to see 100
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh,
                                                                                 target: self,
                                                                                 action: #selector(self
                                                                                     .synchronizeWithRemote))

                        self.navigationItem.rightBarButtonItem?.tintColor = self.navigationItem.leftBarButtonItem?
                            .tintColor
                    }
                }
            default:
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "\(progress)",
                                                                         style: .plain, target: self,
                                                                         action: #selector(self.synchronizeWithRemote))
                self.navigationItem.rightBarButtonItem?.tintColor = TintColorKey.defaultValue
            }
        }
    }

    @objc private func synchronizeWithRemote() {
        guard !isSyncing else {
            return
        }
        isSyncing = true
        AppDelegateKey.defaultValue?.store.synchronize { error in
            let errorString = error?.localizedDescription ?? "Successful sync with remote!"
            Logger.feed.info("\(errorString)")
            DispatchQueue.main.async {
                if error != nil {
                    self.navigationItem.rightBarButtonItem?.tintColor = .red
                } else {
                    self.navigationItem.rightBarButtonItem?.tintColor = self.navigationItem.leftBarButtonItem?.tintColor
                }
                self.isSyncing = false
            }
        }
    }

    @objc private func reloadView(_: Notification? = nil) {
        guard !isLoading else {
            return
        }
        DispatchQueue.main.async {
            self.isLoading = true
            self.reload()
        }
    }

    /*
     This will be called each time the selected date changes.
     Use this as an opportunity to rebuild the content shown to the user.
     */
    override func dailyPageViewController(_: OCKDailyPageViewController,
                                          prepare listViewController: OCKListViewController, for date: Date) {
        Task {
            guard await Utility.checkIfOnboardingIsComplete() else {
                let onboardSurvey = Onboard()
                var query = OCKEventQuery(for: Date())
                query.taskIDs = [Onboard.identifier()]
                let onboardCard = OCKSurveyTaskViewController(eventQuery: query,
                                                              store: self.store,
                                                              survey: onboardSurvey.createSurvey(),
                                                              extractOutcome: { _ in [OCKOutcomeValue(Date())] })
                onboardCard.surveyDelegate = self

                listViewController.clear()
                listViewController.appendViewController(
                    onboardCard,
                    animated: false
                )
                self.isLoading = false
                return
            }

            do {
                let tasks = try await fetchTasks(on: date)
                let isCurrentDay = Calendar.current.isDate(date, inSameDayAs: Date())
                let isTommorow = Calendar.current.isDate(date, inSameDayAs: Date.tomorrow)
                let taskCards = tasks.compactMap {
                    let cards = self.taskViewController(for: $0,
                                                        on: date)
                    cards?.forEach {
                        if let carekitView = $0.view as? OCKView {
                            carekitView.customStyle = CustomStylerKey.defaultValue
                        }
                        $0.view.isUserInteractionEnabled = isCurrentDay
                        $0.view.alpha = !isCurrentDay ? 0.4 : 1.0
                    }
                    return cards
                }

                // Only show the tip view on the current date
                listViewController.clear()
                if isCurrentDay {
                    if Calendar.current.isDate(date, inSameDayAs: Date()) {
                        // Add a non-CareKit view into the list
                        let tipTitle = "Why is sleep important?"
                        let tipText = "Sleeping regularly can help you feel less tired, "
                            + "improve your mood, and help you think more clearly."
                        let tipView = TipView()
                        tipView.headerView.titleLabel.text = tipTitle
                        tipView.headerView.detailLabel.text = tipText
                        tipView.imageView.image = UIImage(named: "sleep")
                        tipView.customStyle = CustomStylerKey.defaultValue
                        listViewController.appendView(tipView, animated: false)
                    }
                }

                taskCards.forEach { (cards: [UIViewController]) in
                    cards.forEach {
                        listViewController.appendViewController($0, animated: false)
                    }
                }
            } catch {
                Logger.feed.error("Could not fetch tasks: \(error)")
            }

            self.isLoading = false
        }
    }

    private func getStoreFetchRequestEvent(for taskId: String) -> CareStoreFetchedResult<OCKAnyEvent>? {
        events?.filter { $0.result.task.id == taskId }.last
    }

    // swiftlint:disable:next cyclomatic_complexity - This
    fileprivate func getCardForTask(
        _ cardView: CareKitCard?,
        _ task: OCKAnyTask,
        _ query: OCKEventQuery,
        _ date: Date
    ) -> [UIViewController]? {
        switch cardView {
        case .numericProgress:
            guard let event = getStoreFetchRequestEvent(for: task.id) else {
                return nil
            }
            let view = NumericProgressTaskView<_NumericProgressTaskViewHeader>(event: event, numberFormatter: .none)
                .careKitStyle(CustomStylerKey.defaultValue)

            return [view.formattedHostingController()]

        case .instructionsTask:
            return [OCKInstructionsTaskViewController(query: query,
                                                      store: store)]

        case .simpleTask:
            return [OCKSimpleTaskViewController(query: query,
                                                store: store)]

        case .checklist:

            return [OCKChecklistTaskViewController(query: query,
                                                   store: store)]

        case .button:
            var cards = [UIViewController]()
            // dynamic gradient colors
            let nauseaGradientStart = TintColorFlipKey.defaultValue
            let nauseaGradientEnd = TintColorKey.defaultValue

            // Create a plot comparing nausea to medication adherence.
            let insomniaDataSeries = OCKDataSeriesConfiguration(
                taskID: task.id,
                legendTitle: task.title ?? "",
                gradientStartColor: nauseaGradientStart,
                gradientEndColor: nauseaGradientEnd,
                markerSize: 10
            ) { event in
                event.computeProgress(by: .summingOutcomeValues)
            }

            let sleepingPillDataSeries = OCKDataSeriesConfiguration(
                taskID: task.id,
                legendTitle: TaskID.sleepingPill,
                gradientStartColor: .systemGray2,
                gradientEndColor: .systemGray,
                markerSize: 10
            ) { event in
                event.computeProgress(by: .summingOutcomeValues)
            }

            let insightsCard = OCKCartesianChartViewController(
                plotType: .bar,
                selectedDate: date,
                configurations: [insomniaDataSeries, sleepingPillDataSeries],
                store: store
            )

            insightsCard.typedView.headerView.titleLabel.text = "Insomnia & Sleeping Pill Intake"
            insightsCard.typedView.headerView.detailLabel.text = "This Week"
            insightsCard.typedView.headerView.accessibilityLabel = "Insomnia & Sleeping Pill Intake, This Week"
            cards.append(insightsCard)

            /*
             Also create a card that displays a single event.
             The event query passed into the initializer specifies that only
             today's log entries should be displayed by this log task view controller.
             */
            let nauseaCard = OCKButtonLogTaskViewController(query: query,
                                                            store: store)
            cards.append(nauseaCard)
            return cards

        case .labeledValueTask:
            guard let event = getStoreFetchRequestEvent(for: task.id) else {
                return nil
            }
            let view = LabeledValueTaskView<_LabeledValueTaskViewHeader>(event: event, numberFormatter: .none)
                .careKitStyle(CustomStylerKey.defaultValue)

            return [view.formattedHostingController()]

        case .link:
            let linkView = LinkView(title: .init("Sleep Tips"),
                                    links: [.website(
                                        // swiftlint:disable:next line_length
                                        "https://www.mayoclinic.org/healthy-lifestyle/adult-health/in-depth/sleep/art-20048379",
                                        title: "Six Tips for Better Sleep"
                                    )])
            return [linkView.formattedHostingController()]

        case .survey:
            guard let surveyTask = task as? OCKTask else {
                Logger.feed.error("Can only use a survey for an \"OCKTask\", not \(task.id)")
                return nil
            }

            let surveyCard = OCKSurveyTaskViewController(
                eventQuery: query,
                store: store,
                survey: surveyTask.survey.type().createSurvey(),
                viewSynchronizer: SurveyViewSynchronizer(),
                extractOutcome: surveyTask.survey.type().extractAnswers
            )
            surveyCard.surveyDelegate = self
            return [surveyCard]

        default:
            // Check if a healthKit task
            guard task is OCKHealthKitTask else {
                return [OCKSimpleTaskViewController(query: query,
                                                    store: store)]
            }

            guard let event = getStoreFetchRequestEvent(for: task.id) else {
                return nil
            }

            let view = LabeledValueTaskView<_LabeledValueTaskViewHeader>(event: event, numberFormatter: .none)
                .careKitStyle(CustomStylerKey.defaultValue)

            return [view.formattedHostingController()]
        }
    }

    private func taskViewController(for task: OCKAnyTask,
                                    on date: Date) -> [UIViewController]? {
        var query = OCKEventQuery(for: Date())
        query.taskIDs = [task.id]

        let cardView: CareKitCard!

        if let task = task as? OCKTask {
            cardView = task.card
        } else if let task = task as? OCKHealthKitTask {
            cardView = task.card
        } else {
            return nil
        }

        return getCardForTask(cardView, task, query, date)
    }

    private func fetchTasks(on date: Date) async throws -> [OCKAnyTask] {
        var query = OCKTaskQuery(for: date)
        query.excludesTasksWithNoEvents = true
        let tasks = try await store.fetchAnyTasks(query: query)

        // Remove onboarding tasks from array
        let filteredTasks = tasks.filter { $0.id != Onboard.identifier() }
        return filteredTasks
    }
}

private extension View {
    func formattedHostingController() -> UIHostingController<Self> {
        let viewController = UIHostingController(rootView: self)
        viewController.view.backgroundColor = .clear
        return viewController
    }
}

extension CareViewController: OCKSurveyTaskViewControllerDelegate {
    func surveyTask(viewController _: OCKSurveyTaskViewController,
                    for _: OCKAnyTask,
                    didFinish result: Result<ORKTaskViewControllerFinishReason, Error>) {
        if case let .success(reason) = result, reason == .completed {
            reload()
        }
    }
}
