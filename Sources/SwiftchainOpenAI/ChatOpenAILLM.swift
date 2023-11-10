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
/// It represents a Large Language Model (LLM) from OpenAI's Chat API. It's used to facilitate conversation-based tasks.
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
  ///   - functions: A list of functions available for the model or `nil`.
  ///   - temperature: The temperature for model's response generation.
  ///   - numberOfVariants: The number of response variants the API should return.
  ///   - model: The language model to be used.
  ///   - apiKey: The OpenAI API key.
  /// - Returns: The `Variants` struct representing the response.
  /// - Throws: An error of type `ChatOpenAILLM.Error` if there's a problem.
  public func invoke(
    _ request: Messages,
    functions: [Function]? = nil,
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
      functions: functions,
      apiKey: apiKey
    )
    return .init(messages: messages)
  }
  
  /// Asynchronously communicates with the OpenAI API. Allows default properties to be overridden.
  ///
  /// - Parameters:
  ///   - request: The `Messages` struct representing the request.
  ///   - functions: A list of functions available for the model or `nil`.
  ///   - temperature: The temperature for model's response generation.
  ///   - numberOfVariants: The number of response variants the API should return.
  ///   - model: The language model to be used.
  ///   - apiKey: The OpenAI API key.
  /// - Returns: The `Variants` struct representing the response.
  /// - Throws: An error of type `ChatOpenAILLM.Error` if there's a problem.
  public func stream(
    _ request: Messages,
    functions: [Function]? = nil,
    temperature: Double? = nil,
    numberOfVariants: Int? = nil,
    model: String? = nil,
    apiKey: String? = nil
  ) throws -> any AsyncSequence {
    guard let apiKey = apiKey ?? self.apiKey ?? ProcessInfo.processInfo.openAIApiKey else {
      throw Error.missingApiKey
    }
    return try streamChat(
      model: model ?? defaultModel,
      temperature: temperature ?? defaultTemperature, 
      variants: numberOfVariants ?? defaultNumberOfVariants, 
      messages: request,
      functions: functions,
      apiKey: apiKey
    )
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
}

public extension ChatOpenAILLM {
  /// Represents a message in a conversation. Includes a role and content.
  struct Message: Codable, Equatable, Hashable {
    public var role: Role
    public var content: String?
    public var name: String? // `name` should be `nil` for all roles except `function`, where it should be the name of the function whose response is in `content` 
    public var functionCall: FunctionCall?
    
    public init(
      role: Role, 
      content: String?,
      name: String? = nil, 
      functionCall: FunctionCall? = nil
    ) {
      self.role = role
      self.content = content
      self.name = name
      self.functionCall = functionCall
    }
    
    public init(from decoder: Decoder) throws {
      let container: KeyedDecodingContainer<ChatOpenAILLM.Message.CodingKeys> = try decoder.container(keyedBy: ChatOpenAILLM.Message.CodingKeys.self)
      self.role = try container.decodeIfPresent(ChatOpenAILLM.Role.self, forKey: ChatOpenAILLM.Message.CodingKeys.role) ?? .assistant
      self.content = try container.decodeIfPresent(String.self, forKey: ChatOpenAILLM.Message.CodingKeys.content)
      self.name = try container.decodeIfPresent(String.self, forKey: ChatOpenAILLM.Message.CodingKeys.name)
      self.functionCall = try container.decodeIfPresent(ChatOpenAILLM.FunctionCall.self, forKey: ChatOpenAILLM.Message.CodingKeys.functionCall)
    }
  }
  
  /// Enum representing the role of a message sender in a conversation.
  enum Role: Codable, Equatable, Hashable, RawRepresentable {
    case system
    case user
    case assistant
    case function
    case custom(String)
    
    public init?(rawValue: String) {
      switch rawValue {
      case "assistant":
        self = .assistant
      case "user":
        self = .user
      case "system":
        self = .system
      case "function":
        self = .function
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
      case .function:
        return "function"
      case .custom(let rawValue):
        return rawValue
      }
    }
  }
  
  struct FunctionCall: Codable, Equatable, Hashable {
    public var name: String?
    public var arguments: String
    
    public init(name: String, arguments: String) {
      self.name = name
      self.arguments = arguments
    }
  }
  
  struct Function: Codable, Equatable, Hashable {
    public var name: String // The name of the function to be called. Must be a-z, A-Z, 0-9, or contain underscores and dashes, with a maximum length of 64.
    public var description: String // The description of what the function does.
    public var parameters: ParameterDescription // The parameters the functions accepts, described as a JSON Schema object.
    
    public init(
      name: String, 
      description: String, 
      parameters: ParameterDescription
    ) {
      self.name = name
      self.description = description
      self.parameters = parameters
    }
  }
  
  struct ParameterDescription: Codable, Equatable, Hashable {
    public var type: String
    public var properties: [String: Property]
    public var required: [String]
    
    public init(type: String, properties: [String : Property], required: [String]) {
      self.type = type
      self.properties = properties
      self.required = required
    }
  }
  
  struct Property: Codable, Equatable, Hashable {
    public var type: String
    public var description: String
    public var `enum`: [String]?
    public var items: ArrayProperty?
    
    public init(
      type: String, 
      description: String, 
      `enum`: [String]? = nil,
      items: ArrayProperty? = nil
    ) {
      self.type = type
      self.description = description
      self.enum = `enum`
      self.items = items
    }
  }
    
  class ArrayProperty: Codable, Equatable, Hashable {
    public var type: String
    public var items: ArrayProperty?
    
    public init(type: String, items: ArrayProperty? = nil) {
      self.type = type
      self.items = items
    }
    
    public static func == (lhs: ChatOpenAILLM.ArrayProperty, rhs: ChatOpenAILLM.ArrayProperty) -> Bool {
      lhs.type == rhs.type && lhs.items == rhs.items
    }
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(type)
      hasher.combine(items)
    }
  }
}
