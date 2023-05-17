//
//  OpenAI.swift
//  
//
//  Created by Toni K. Turk on 14/05/2023.
//

import Swiftchain
import Foundation

public struct ChatOpenAILLM: LLM {
  public let apiKey: String?
  public let defaultTemperature: Double
  public let defaultNumberOfVariants: Int
  public let defaultModel: String
  let api: API = .init()
  
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
  
  public func invoke(_ request: Encodable) async throws -> Decodable {
    let messages = try validateRequest(request)
    return try await invoke(messages: messages)
  }
  
  public func invoke(_ request: Encodable) async throws -> [String] {
    let messages = try validateRequest(request)
    return try await invoke(messages: messages, apiKey: apiKey)
  }
  
  public func invoke(
    messages: Messages,
    temperature: Double? = nil,
    numberOfVariants: Int? = nil,
    model: String? = nil,
    apiKey: String? = nil
  ) async throws -> [String] {
    guard let apiKey = apiKey ?? self.apiKey ?? ProcessInfo.processInfo.openAIApiKey else {
      throw Error.missingApiKey
    }
    return try await api.chat(
      model: model ?? defaultModel,
      temperature: temperature ?? defaultTemperature, 
      variants: numberOfVariants ?? defaultNumberOfVariants, 
      messages: messages,
      apiKey: apiKey
    )
  }
  
  public func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, String>) async throws -> Decodable {
    var apiKey = apiKey ?? ProcessInfo.processInfo.openAIApiKey
    var temperature = defaultTemperature
    var numberOfVariants = defaultNumberOfVariants
    var model = defaultModel
    var request: String?
    for arg in args {
      switch arg.key {
      case "apiKey":
        apiKey = arg.value
      case "temperature":
        temperature = Double(arg.value) ?? temperature
      case "numberOfVariants":
        numberOfVariants = Int(arg.value) ?? numberOfVariants
      case "model":
        model = arg.value
      case "request":
        request = arg.value
      case _:
        continue
      }
    }
    guard let apiKey = apiKey ?? ProcessInfo.processInfo.openAIApiKey else {
      throw Error.missingApiKey
    }
    guard let request else {
      throw Error.missingRequest
    }
    let messages = try validateRequest(request)
    return try await api.chat(
      model: model,
      temperature: temperature, 
      variants: defaultNumberOfVariants, 
      messages: messages,
      apiKey: apiKey
    )
  }
}

public extension ChatOpenAILLM {
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
  
  struct Message: Codable, Equatable, Hashable {
    public let role: Role
    public let content: String
    
    public init(role: Role, content: String) {
      self.role = role
      self.content = content
    }
  }
}

extension ChatOpenAILLM {
  func validateRequest(_ request: Encodable) throws -> Messages {
    guard let messages = request as? Messages else {
      throw Error.invalidRequest(type(of: request))
    }
    return messages
  } 
}

struct API {
  func chat(
    model: String,
    temperature: Double,
    variants: Int,
    messages: ChatOpenAILLM.Messages,
    apiKey: String
  ) async throws -> [String] {
    struct Request: Encodable {
      let model: String
      let messages: [ChatOpenAILLM.Message]
      let temperature: Double
      let n: Int
    }
    let request = Request(
      model: model, 
      messages: messages, 
      temperature: temperature,
      n: variants
    )
    
    let data = try await post(
      to: "https://api.openai.com/v1/chat/completions", 
      request: request,
      headers: ["Authorization": "Bearer \(apiKey)"]
    )
    
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { 
      throw NSError()
    }
    return ((((json["choices"] as? [[String: Any]])?[0] as? [String: Any])?["message"] as? [String: Any])?["content"] as? String).map { [$0] } ?? []
  }
}


extension ProcessInfo {
  var openAIApiKey: String? {
    self.environment["OPEN_AI_API_KEY"]
  }
}
