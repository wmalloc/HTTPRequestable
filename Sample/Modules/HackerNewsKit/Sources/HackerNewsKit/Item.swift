//
//  Item.swift
//
//  Created by Waqar Malik on 9/7/24.
//

import Foundation

public struct Item: Codable, Hashable, Identifiable, Sendable {
  public let id: Int
  public let by: String
  public let descendants: Int?
  public let kids: [Int]?
  public let score: Int
  public let time: Date
  public let title: String
  public let type: String
  public let url: URL?

  public init(id: Int, by: String, descendants: Int?, kids: [Int]?, score: Int, time: Date, title: String, type: String, url: URL?) {
    self.id = id
    self.by = by
    self.descendants = descendants
    self.kids = kids
    self.score = score
    self.time = time
    self.title = title
    self.type = type
    self.url = url
  }
}

// MARK: - Codable

/// Hacker News sends `time` as seconds since the Unix epoch. `time` is coded explicitly so the
/// conversion holds for any decoder, rather than relying on a caller configuring
/// `JSONDecoder.dateDecodingStrategy`; the default strategy would read the value as seconds since
/// the 2001 reference date and place every item three decades into the future.
public extension Item {
  private enum CodingKeys: String, CodingKey {
    case id, by, descendants, kids, score, time, title, type, url
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(Int.self, forKey: .id)
    self.by = try container.decode(String.self, forKey: .by)
    self.descendants = try container.decodeIfPresent(Int.self, forKey: .descendants)
    self.kids = try container.decodeIfPresent([Int].self, forKey: .kids)
    self.score = try container.decode(Int.self, forKey: .score)
    self.time = try Date(timeIntervalSince1970: container.decode(TimeInterval.self, forKey: .time))
    self.title = try container.decode(String.self, forKey: .title)
    self.type = try container.decode(String.self, forKey: .type)
    self.url = try container.decodeIfPresent(URL.self, forKey: .url)
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(by, forKey: .by)
    try container.encodeIfPresent(descendants, forKey: .descendants)
    try container.encodeIfPresent(kids, forKey: .kids)
    try container.encode(score, forKey: .score)
    try container.encode(time.timeIntervalSince1970, forKey: .time)
    try container.encode(title, forKey: .title)
    try container.encode(type, forKey: .type)
    try container.encodeIfPresent(url, forKey: .url)
  }
}
