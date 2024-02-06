//
//  Run.swift
//  
//
//  Created by Toni K. Turk on 12. 11. 23.
//

import Foundation
import Swiftchain

public struct Run: Codable, Identifiable {
  public var id: String
  public var status: Status
  public var lastError: RunError?
  // TODO: - Add all the data
}

public extension Run {
  enum Status: String, Codable {
    case queued
    case inProgress = "in_progress"
    case requiresAction = "requires_action"
    case cancelling
    case cancelled
    case failed
    case completed
    case expired
  }
  
  struct RunError: Codable {
    var code: String
    var message: String
  }
}

public func createRun(
  threadId: Thread.ID,
  assistantId: Assistant.ID,
  // TODO: - Add other params
  apiKey: String
) async throws -> Run {
  struct Request: Encodable {
    let assistantId: Assistant.ID
  }
  return try await post(
    to: .init(string: "https://api.openai.com/v1/threads/\(threadId)/runs")!,
    request: Request(
      assistantId: assistantId
    ),
    headers: [
      "Authorization": "Bearer \(apiKey)",
      "OpenAI-Beta": "assistants=v1",
    ],
    encoder: encoder,
    decoder: decoder
  )
}

public func listRuns(
  threadId: Thread.ID,
  limit: Int? = nil, // default 20
  orderBy: OrderBy? = nil,
  after: Assistant.ID? = nil, // pagination
  before: Assistant.ID? = nil, // pagination
  apiKey: String
) async throws -> [Run] {
  var components = URLComponents(string: "https://api.openai.com/v1/threads/\(threadId)/runs")!
  components.queryItems = []
  if let limit {
    components.queryItems!.append(.init(name: "limit", value: String(limit)))
  }
  if let orderBy {
    components.queryItems!.append(.init(name: "orderBy", value: orderBy.rawValue))
  }
  return try await get(
    to: components.url!,
    headers: [
      "Authorization": "Bearer \(apiKey)",
      "OpenAI-Beta": "assistants=v1",
    ],    
    decode: List<Run>.self,
    decoder: decoder
  ).data
}
