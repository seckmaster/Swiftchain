//
//  ChatOpenAILLM.swift
//  
//
//  Created by Toni K. Turk on 18/05/2023.
//

import Foundation
import Swiftchain

/// `ChatOpenAILLM` is a struct that conforms to the `LLM` protocol. 
/// 
/// It represents a language learning model (LLM) from OpenAI's Chat API. It's used to facilitate conversation-based tasks.
public struct ChatOpenAILLM: LLM {
  public struct Variants {
    public let messages: [Message]
  }
  
  /// The OpenAI API key. Can be `nil` if the environment variable is used.
  public let apiKey: String?
  /// Default temperature for the model's response generation.
  public let defaultTemperature: Double
  /// Default number of response variants the API should return.
  public let defaultNumberOfVariants: Int
  /// Default language model to be used, which is "gpt-4" in this case.
  public let defaultModel: String
  
  /// Initializes a `ChatOpenAILLM` instance.
  ///
  /// - Parameters:
  ///   - apiKey: The OpenAI API key.
  ///   - defaultTemperature: The default temperature for model's response generation.
  ///   - defaultNumberOfVariants: The default number of response variants the API should return.
  ///   - defaultModel: The default language model to be used.
  public init(
    apiKey: String? = nil, 
    defaultTemperature: Double = 0.0, 
    defaultNumberOfVariants: Int = 1,
    defaultModel: String = "gpt-4"
  ) {
    self.apiKey = apiKey
    self.defaultTemperature = defaultTemperature
    self.defaultNumberOfVariants = defaultNumberOfVariants
    self.defaultModel = defaultModel
  }
  
  /// Asynchronously communicates with the OpenAI API using default properties.
  ///
  /// - Parameter request: The `Messages` struct representing the request.
  /// - Returns: The `Variants` struct representing the response.
  /// - Throws: An error of type `ChatOpenAILLM.Error` if there's a problem.
  public func invoke(_ request: Messages) async throws -> Variants {
    try await invoke(
      request,
      temperature: nil
    )
  }
  
  /// Asynchronously communicates with the OpenAI API. Allows default properties to be overridden.
  ///
  /// - Parameters:
  ///   - request: The `Messages` struct representing the request.
  ///   - temperature: The temperature for model's response generation.
  ///   - numberOfVariants: The number of response variants the API should return.
  ///   - model: The language model to be used.
  ///   - apiKey: The OpenAI API key.
  /// - Returns: The `Variants` struct representing the response.
  /// - Throws: An error of type `ChatOpenAILLM.Error` if there's a problem.
  public func invoke(
    _ request: Messages,
    temperature: Double? = nil,
    numberOfVariants: Int? = nil,
    model: String? = nil,
    apiKey: String? = nil
  ) async throws -> Variants {
    guard let apiKey = apiKey ?? self.apiKey ?? ProcessInfo.processInfo.openAIApiKey else {
      throw Error.missingApiKey
    }
    let messages = try await chat(
      model: model ?? defaultModel,
      temperature: temperature ?? defaultTemperature, 
      variants: numberOfVariants ?? defaultNumberOfVariants, 
      messages: request,
      apiKey: apiKey
    )
    return .init(messages: messages)
  }
}

public extension ChatOpenAILLM {
  /// Enum representing potential errors that can occur when using `ChatOpenAILLM`.
  enum Error: LocalizedError {
    case missingApiKey
    case invalidRequest(Encodable.Type)
    case missingRequest
    
    public var errorDescription: String? {
      switch self {
      case .missingApiKey:
        return "Could not locate OpenAI API key!"
      case .invalidRequest(let type):
        return "Could not convert \(type) to expected model."
      case .missingRequest:
        return "Request not present in **kwargs."
      }
    }
    
    public var recoverySuggestion: String? {
      switch self {
      case .missingApiKey:
        return "Save your OpenAI API key as an environment variable or use it in the `ChatOpenAILLM` initializer."
      case .invalidRequest:
        return """
OpenAI chat based API's expect the following JSON schema:

```JSON
[
  {
    "role": "system",
    "message": "You are a helpful assistant!" 
  },
  {
    "role": "user",
    "message": "Who is Albert Einstein?"
  },
  ...
]
```
"""
      case .missingRequest:
        return "Provide a value with 'request' key inside the **kwargs."
      }
    }
  }
  
  typealias Messages = [Message]
  
  /// Enum representing the role of a message sender in a conversation.
  enum Role: Codable, Equatable, Hashable, RawRepresentable {
    case system
    case user
    case assistant
    case custom(String)
    
    public init?(rawValue: String) {
      switch rawValue {
      case "assistant":
        self = .assistant
      case "user":
        self = .user
      case "system":
        self = .system
      case _:
        self = .custom(rawValue)
      }
    }
    
    public var rawValue: String {
      switch self {
      case .assistant:
        return "assistant"
      case .system:
        return "system"
      case .user:
        return "user"
      case .custom(let rawValue):
        return rawValue
      }
    }
  }
  
  /// Represents a message in a conversation. Includes a role and content.
  struct Message: Codable, Equatable, Hashable {
    public let role: Role
    public let content: String
    
    /// Initializes a `Message` instance.
    ///
    /// - Parameters:
    ///   - role: The role of the sender of the message.
    ///   - content: The content of the message.
    public init(role: Role, content: String) {
      self.role = role
      self.content = content
    }
  }
}
