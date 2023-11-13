//
//  Assistant.swift
//  
//
//  Created by Toni K. Turk on 12. 11. 23.
//

import Foundation
import Swiftchain

// https://platform.openai.com/docs/api-reference/assistants/createAssistant

public enum Tool: String, Codable {
  case interpreter = "code_interpreter"
  case retrieval
  case function
}

public struct Assistant: Codable, Identifiable {
  public var id: String
  public var object: String
  public var createdAt: Date
  public var name: String?
  public var description: String?
  public var model: String
  public var instructions: String?
  public var tools: [Tool]?
  public var fileIds: [String]?
  public var metadata: [String: String]
}

public func createAssistant(
  name: String, // 256 chars
  description: String?, // 512 chars
  model: String,
  instructions: String?, // 'system prompt' 32768 characters
  tools: [Tool]? = nil,
  fileIds: [String]? = nil,
  metadata: [String: String]? = nil, // 16 key-value pairs
  apiKey: String
) async throws -> Assistant {
  struct Request: Encodable {
    let model: String
    let name: String?
    let description: String?
    let instructions: String?
    let tools: [Tool]?
    let fileIds: [String]?
    let metadata: [String: String]?
  }
  return try await post(
    to: "https://api.openai.com/v1/assistants",
    request: Request(
      model: model,
      name: name,
      description: description,
      instructions: instructions,
      tools: tools,
      fileIds: fileIds,
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

public func retrieve(
  assistant withId: Assistant.ID,
  apiKey: String
) async throws -> Assistant {
  try await get(
    to: .init(string: "https://api.openai.com/v1/assistants/\(withId)")!,
    headers: [
      "Authorization": "Bearer \(apiKey)",
      "OpenAI-Beta": "assistants=v1",
    ], 
    decoder: decoder
  )
}

// @TODO: - 
// public func modify

public enum OrderBy: String {
  case asc, desc
}

public func assistants(
  limit: Int? = nil, // default 20
  orderBy: OrderBy? = nil,
  after: Assistant.ID? = nil, // pagination
  before: Assistant.ID? = nil, // pagination
  apiKey: String
) async throws -> [Assistant] {
  var components = URLComponents(string: "https://api.openai.com/v1/assistants")!
  components.queryItems = []
  if let limit {
    components.queryItems!.append(.init(name: "limit", value: String(limit)))
  }
  if let orderBy {
    components.queryItems!.append(.init(name: "orderBy", value: orderBy.rawValue))
  }
  // TODO: - Pagination
  return try await get(
    to: components.url!,
    headers: [
      "Authorization": "Bearer \(apiKey)",
      "OpenAI-Beta": "assistants=v1",
    ],
    decode: List<Assistant>.self,
    decoder: decoder
  ).data
}

public struct AssistantFile: Codable, Identifiable {
  public var id: String
  public var object: String
  public var createdAt: Date
  public var assistantID: Assistant.ID
}

public func attach(
  file withId: AssistantFile.ID,
  toAssistant assistantId: Assistant.ID,
  apiKey: String
) async throws -> AssistantFile {
  try await post(
    to: .init(string: "https://api.openai.com/v1/assistants/\(assistantId)/files")!,
    request: ["file_id": withId],
    headers: [
      "Authorization": "Bearer \(apiKey)",
      "OpenAI-Beta": "assistants=v1",
    ]
  )
}

public func retrieve(
  assistantId: Assistant.ID,
  fileId: AssistantFile.ID,
  apiKey: String
) async throws -> AssistantFile {
  try await get(
    to: .init(string: "https://api.openai.com/v1/assistants/\(assistantId)/files/\(fileId)")!,
    headers: [
      "Authorization": "Bearer \(apiKey)",
      "OpenAI-Beta": "assistants=v1",
    ],
    decoder: decoder 
  )
}

public func assistantFiles(
  assistantId: Assistant.ID,
  limit: Int? = nil, // default 20
  orderBy: OrderBy?,
  after: Assistant.ID? = nil, // pagination
  before: Assistant.ID? = nil, // pagination
  apiKey: String
) async throws -> [AssistantFile] {
  var components = URLComponents(string: "https://api.openai.com/v1/assistants/\(assistantId)/files")!
  components.queryItems = []
  if let limit {
    components.queryItems!.append(.init(name: "limit", value: String(limit)))
  }
  if let orderBy {
    components.queryItems!.append(.init(name: "orderBy", value: orderBy.rawValue))
  }
  // TODO: - Pagination
  return try await get(
    to: components.url!,
    headers: [
      "Authorization": "Bearer \(apiKey)",
      "OpenAI-Beta": "assistants=v1",
    ],
    decoder: decoder 
  )
}
