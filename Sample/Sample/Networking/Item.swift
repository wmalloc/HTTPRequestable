//
//  Item.swift
//  Sample
//
//  Created by Waqar Malik on 9/7/24.
//

import Foundation

struct Item: Codable, Hashable, Sendable, Identifiable {
  let id: Int
  let by: String
  let descendants: Int?
  let kids: [Int]?
  let score: Int
  let time: Date
  let title: String
  let type: String
  let url: URL?
}
