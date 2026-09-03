//
//  StoryTypeTests.swift
//
//  Created by Waqar Malik on 8/27/26.
//

import Foundation
@testable import HackerNewsKit
import Testing

@Suite("StoryType")
struct StoryTypeTests {
  @Test("Raw values match the Hacker News endpoint names")
  func rawValues() {
    #expect(StoryType.top.rawValue == "topstories")
    #expect(StoryType.new.rawValue == "newstories")
    #expect(StoryType.best.rawValue == "beststories")
    #expect(StoryType.show.rawValue == "showstories")
    #expect(StoryType.job.rawValue == "jobstories")
  }

  @Test("Identifier is the raw value", arguments: StoryType.allCases)
  func identifierIsRawValue(type: StoryType) {
    #expect(type.id == type.rawValue)
  }

  @Test("Every case has a non empty display title", arguments: StoryType.allCases)
  func titleIsNotEmpty(type: StoryType) {
    #expect(!type.title.isEmpty)
  }

  @Test("Display titles")
  func titles() {
    #expect(StoryType.top.title == "Top")
    #expect(StoryType.new.title == "New")
    #expect(StoryType.best.title == "Best")
    #expect(StoryType.show.title == "Show")
    #expect(StoryType.job.title == "Jobs")
  }

  @Test("All cases are present and uniquely identified")
  func allCases() {
    #expect(StoryType.allCases.count == 5)
    #expect(Set(StoryType.allCases.map(\.id)).count == StoryType.allCases.count)
  }

  @Test("Round trips through its raw value", arguments: StoryType.allCases)
  func roundTrip(type: StoryType) {
    #expect(StoryType(rawValue: type.rawValue) == type)
  }
}
