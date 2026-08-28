//
//  StoryType.swift
//
//  Created by Waqar Malik on 9/7/24.
//

import Foundation

public enum StoryType: String, CaseIterable, Identifiable, Sendable {
  case top = "topstories"
  case new = "newstories"
  case best = "beststories"
  case show = "showstories"
  case job = "jobstories"

  public var id: String {
    rawValue
  }

  public var title: String {
    switch self {
    case .top: "Top"
    case .new: "New"
    case .best: "Best"
    case .show: "Show"
    case .job: "Jobs"
    }
  }
}
