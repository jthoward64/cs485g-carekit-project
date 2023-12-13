//
//  Surveyable.swift
//  OCKSample
//
//  Created by Joshua Howard on 12/12/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Foundation
#if canImport(ResearchKit)
  import ResearchKit
#endif

/**
 Correlates a CareKit task with a ResearchKit task.
 */
protocol Surveyable {
  /// The type of survey.
  static var surveyType: Survey { get }
  /// The unique identifier of the survey.
  static func identifier() -> String
  #if canImport(ResearchKit)
    /// Creates the survey.
    func createSurvey() -> ORKTask
    /// Extracts the answers from the survey.
    func extractAnswers(_ result: ORKTaskResult) -> [OCKOutcomeValue]?
  #endif
}

extension Surveyable {
  static func identifier() -> String {
    surveyType.rawValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// The unique identifier of the survey.
  func identifier() -> String {
    Self.identifier()
  }
}
