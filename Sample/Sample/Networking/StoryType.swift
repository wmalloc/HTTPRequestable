//
//  StoryType.swift
//
//  Created by Waqar Malik on 9/7/24.
//

enum StoryType: String, CaseIterable, Identifiable {
  case top = "topstories"
  case new = "newstories"
  case best = "beststories"
  case show = "showstories"
  case job = "jobstories"

  var id: String {
    rawValue
  }

  var title: String {
    switch self {
    case .top: "Top"
    case .new: "New"
    case .best: "Best"
    case .show: "Show"
    case .job: "Jobs"
    }
  }
}
