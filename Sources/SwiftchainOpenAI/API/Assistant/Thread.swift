//
//  Thread.swift
//  
//
//  Created by Toni K. Turk on 12. 11. 23.
//

import Foundation
import Swiftchain

public struct Thread: Codable, Identifiable {
  public var id: String
  public var object: String
  public var createdAt: Date
  public var metadata: [String: String]
}

public func createThread(
  initialHistory messages: [Message]? = nil,
  metadata: [String: String]? = nil,
  apiKey: String
) async throws -> Thread {
  struct Request: Encodable {
    let messages: [Message]?
    let metadata: [String: String]?
  }
  return try await post(
    to: "https://api.openai.com/v1/threads", 
    request: Request(
      messages: messages,
      metadata: metadata
    ),
    headers: [
      "Authorization": "Bearer \(apiKey)",
      "OpenAI-Beta": "assistants=v1",
    ],
    encoder: encoder,
    decoder: decoder
  )
}

public func thread(
  threadId: Thread.ID,
  apiKey: String
) async throws -> Thread {
  try await get(
    to: .init(string: "https://api.openai.com/v1/threads/\(threadId)")!, 
    headers: [
      "Authorization": "Bearer \(apiKey)",
      "OpenAI-Beta": "assistants=v1",
    ],   
    decoder: decoder
  )
}

// TODO: - Modify thread

// TODO: - Delete thread


