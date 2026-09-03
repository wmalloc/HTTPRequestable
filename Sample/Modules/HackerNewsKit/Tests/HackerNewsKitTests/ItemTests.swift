//
//  ItemTests.swift
//
//  Created by Waqar Malik on 8/27/26.
//

import Foundation
@testable import HackerNewsKit
import Testing

@Suite("Item")
struct ItemTests {
  @Test("Decodes a full story payload")
  func decodeStory() throws {
    let json = Data("""
    {
      "by": "dhouston",
      "descendants": 71,
      "id": 8863,
      "kids": [8952, 9224, 8917],
      "score": 111,
      "time": 1175714200,
      "title": "My YC app: Dropbox - Throw away your USB drive",
      "type": "story",
      "url": "http://www.getdropbox.com/u/2/screencast.html"
    }
    """.utf8)

    let item = try JSONDecoder().decode(Item.self, from: json)
    #expect(item.id == 8863)
    #expect(item.by == "dhouston")
    #expect(item.descendants == 71)
    #expect(item.kids == [8952, 9224, 8917])
    #expect(item.score == 111)
    #expect(item.title == "My YC app: Dropbox - Throw away your USB drive")
    #expect(item.type == "story")
    #expect(item.url == URL(string: "http://www.getdropbox.com/u/2/screencast.html"))
  }

  @Test("Decodes a job payload that omits every optional field")
  func decodeJobWithoutOptionals() throws {
    let json = Data("""
    {
      "by": "justin",
      "id": 192327,
      "score": 6,
      "time": 1225146407,
      "title": "Justin.tv is looking for a Lead Flash Engineer",
      "type": "job"
    }
    """.utf8)

    let item = try JSONDecoder().decode(Item.self, from: json)
    #expect(item.descendants == nil)
    #expect(item.kids == nil)
    #expect(item.url == nil)
    #expect(item.type == "job")
  }

  @Test("Decodes time as seconds since the Unix epoch")
  func decodeTime() throws {
    let json = Data("""
    {"by": "a", "id": 1, "score": 1, "time": 1175714200, "title": "t", "type": "story"}
    """.utf8)

    let item = try JSONDecoder().decode(Item.self, from: json)
    #expect(item.time == Date(timeIntervalSince1970: 1175714200))
  }

  /// The conversion lives on the type, not on a `JSONDecoder.dateDecodingStrategy` the caller has to
  /// remember to configure.
  @Test("Decodes time without any decoder configuration")
  func decodeTimeIsDecoderIndependent() throws {
    let json = Data("""
    {"by": "dhouston", "id": 8863, "score": 111, "time": 1175714200, "title": "Dropbox", "type": "story"}
    """.utf8)

    let item = try JSONDecoder().decode(Item.self, from: json)
    let components = try Calendar(identifier: .gregorian).dateComponents(in: #require(TimeZone(identifier: "UTC")), from: item.time)
    #expect(components.year == 2007)
    #expect(components.month == 4)
    #expect(components.day == 4)
  }

  @Test("Encodes time as seconds since the Unix epoch")
  func encodeTime() throws {
    let item = Item(id: 1, by: "a", descendants: nil, kids: nil, score: 1,
                    time: Date(timeIntervalSince1970: 1175714200), title: "t", type: "story", url: nil)

    let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(item)) as? [String: Any]
    let time = try #require(encoded?["time"] as? TimeInterval)
    #expect(time == 1175714200)
  }

  @Test("Fails when a required field is missing")
  func decodeMissingRequiredField() {
    let json = Data("""
    {"id": 1, "score": 1, "time": 1175714200, "title": "t", "type": "story"}
    """.utf8)

    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(Item.self, from: json)
    }
  }

  @Test("Fails on the null body Hacker News returns for an unknown id")
  func decodeNull() {
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(Item.self, from: Data("null".utf8))
    }
  }

  @Test("Round trips through encode and decode")
  func roundTrip() throws {
    let item = Item(id: 42, by: "turing", descendants: 3, kids: [1, 2], score: 10,
                    time: Date(timeIntervalSinceReferenceDate: 1000), title: "On Computable Numbers",
                    type: "story", url: URL(string: "https://example.com"))

    let decoded = try JSONDecoder().decode(Item.self, from: JSONEncoder().encode(item))
    #expect(decoded == item)
  }

  @Test("Identity and equality are driven by the whole value")
  func equality() {
    let item = Item(id: 42, by: "turing", descendants: nil, kids: nil, score: 10,
                    time: Date(timeIntervalSinceReferenceDate: 0), title: "A", type: "story", url: nil)
    let sameIdDifferentTitle = Item(id: 42, by: "turing", descendants: nil, kids: nil, score: 10,
                                    time: Date(timeIntervalSinceReferenceDate: 0), title: "B", type: "story", url: nil)

    #expect(item.id == sameIdDifferentTitle.id)
    #expect(item != sameIdDifferentTitle)
    #expect(item == item)
    #expect(Set([item, item]).count == 1)
  }
}
