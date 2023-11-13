//
//  Message.swift
//  
//
//  Created by Toni K. Turk on 12. 11. 23.
//

import Foundation
import Swiftchain

public struct Message: Codable, Identifiable {
  public var id: String
  public var object: String
  public var createdAt: Date
  public var threadId: Thread.ID
  public var role: Role
  public var content: [Content]
  public var assistantId: Assistant.ID?
  public var runId: Run.ID?
  public var fileIds: [File.ID]
  public var metadata: [String: String]
}

public extension Message {
  enum Role: String, Codable {
    case user
    case assistant
  }
  
  enum Content: Codable {
    case text(String)
    case image(File.ID)
    
    enum OuterCodingKeys: CodingKey {
      case type
      case image
      case text
    }
    
    enum TextCodingKeys: CodingKey {
      case value
      case annotations
    }
    
    enum ImageCodingKeys: CodingKey {
      case fileId
    }
    
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: OuterCodingKeys.self)
      switch self {
      case .image(let id):
        try container.encode("image", forKey: .type)
        var innerContainer = container.nestedContainer(keyedBy: ImageCodingKeys.self, forKey: .image)
        try innerContainer.encode(id, forKey: .fileId)
      case .text(let text):
        try container.encode("text", forKey: .type)
        var innerContainer = container.nestedContainer(keyedBy: TextCodingKeys.self, forKey: .text)
        try innerContainer.encode(text, forKey: .value)
      }
    }
    
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: OuterCodingKeys.self)
      let type = try container.decode(String.self, forKey: .type)
      switch type {
      case "image":
        let innerContainer = try container.nestedContainer(keyedBy: ImageCodingKeys.self, forKey: .image)
        self = .image(try innerContainer.decode(File.ID.self, forKey: .fileId))
      case "text":
        let innerContainer = try container.nestedContainer(keyedBy: TextCodingKeys.self, forKey: .text)
        self = .text(try innerContainer.decode(String.self, forKey: .value))
      case _:
        throw DecodingError.dataCorrupted(.init(codingPath: [OuterCodingKeys.type], debugDescription: "Unknown type: \(type)"))
      }
    }
  }
}

public func createMessage(
  threadId: Thread.ID,
  role: Message.Role,
  content: String,
  fileIds: [File.ID] = [],
  metadata: [String: String]? = nil,
  apiKey: String
) async throws -> Message {
  struct Request: Encodable {
    let role: Message.Role
    let content: String
    let fileIds: [File.ID]
    let metadata: [String: String]?
  }
  return try await post(
    to: .init(string: "https://api.openai.com/v1/threads/\(threadId)/messages")!, 
    request: Request(
      role: role,
      content: content,
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

public func message(
  threadId: Thread.ID,
  messageId: Message.ID,
  apiKey: String
) async throws -> Message {
  try await get(
    to: .init(string: "https://api.openai.com/v1/threads/\(threadId)/messages/\(messageId)")!, 
    headers: [
      "Authorization": "Bearer \(apiKey)",
      "OpenAI-Beta": "assistants=v1",
    ],
    decoder: decoder
  )
}

public func listMessages(
  threadId: Thread.ID,
  limit: Int? = nil, // default 20
  orderBy: OrderBy? = nil,
  after: Assistant.ID? = nil, // pagination
  before: Assistant.ID? = nil, // pagination
  apiKey: String
) async throws -> [Message] {
  var components = URLComponents(string: "https://api.openai.com/v1/threads/\(threadId)/messages")!
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
    decode: List<Message>.self,
    decoder: decoder
  ).data
}

// TODO: - Message file
