//
//  OpenAI.swift
//  
//
//  Created by Toni K. Turk on 14/05/2023.
//

import Swiftchain
import Foundation

extension ProcessInfo {
  var openAIApiKey: String? {
    self.environment["OPEN_AI_API_KEY"]
  }
}

//public struct OpenAILLM: LLM {
//  public let apiKey: String?
//  public let defaultTemperature: Double
//  public let defaultNumberOfVariants: Int
//  public let defaultModel: String
//  
//  public init(
//    apiKey: String? = nil, 
//    defaultTemperature: Double = 0.0, 
//    defaultNumberOfVariants: Int = 1,
//    defaultModel: String = "text-davinci-003"
//  ) {
//    self.apiKey = apiKey
//    self.defaultTemperature = defaultTemperature
//    self.defaultNumberOfVariants = defaultNumberOfVariants
//    self.defaultModel = defaultModel
//  }
//  
//  public func invoke(_ request: Encodable) async throws -> Decodable {
//    guard let prompt = request as? String ?? (request as? CustomStringConvertible)?.description else {
//      throw Error.invalidRequest(type(of: request))
//    }
//    return try await invoke(prompt: prompt)
//  }
//  
//  public func invoke(
//    prompt: String,
//    temperature: Double? = nil,
//    numberOfVariants: Int? = nil,
//    model: String? = nil,
//    apiKey: String? = nil
//  ) async throws -> [String] {
//    guard let apiKey = apiKey ?? self.apiKey ?? ProcessInfo.processInfo.openAIApiKey else {
//      throw Error.missingApiKey
//    }
//    return try await completion(
//      model: model ?? defaultModel,
//      temperature: temperature ?? defaultTemperature, 
//      variants: numberOfVariants ?? defaultNumberOfVariants, 
//      prompt: prompt,
//      apiKey: apiKey
//    )
//  }
//}
//
//public extension OpenAILLM {
//  enum Error: LocalizedError {
//    case missingApiKey
//    case invalidRequest(Encodable.Type)
//    case missingRequest
//    
//    public var errorDescription: String? {
//      switch self {
//      case .missingApiKey:
//        return "Could not locate OpenAI API key!"
//      case .invalidRequest(let type):
//        return "Could not convert \(type) to expected model."
//      case .missingRequest:
//        return "Request not present in **kwargs."
//      }
//    }
//    
//    public var recoverySuggestion: String? {
//      switch self {
//      case .missingApiKey:
//        return "Save your OpenAI API key as an environment variable or use it in the `ChatOpenAILLM` initializer."
//      case .invalidRequest:
//        return """
//OpenAI completion based API's expect the argument to be a `String`.
//```
//"""
//      case .missingRequest:
//        return "Provide a value with 'request' key inside the **kwargs."
//      }
//    }
//  }
//}
