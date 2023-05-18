//
//  API.swift
//  
//
//  Created by Toni K. Turk on 17/05/2023.
//

import Swiftchain
import Foundation

func chat(
  model: String,
  temperature: Double,
  variants: Int,
  messages: ChatOpenAILLM.Messages,
  apiKey: String
) async throws -> [ChatOpenAILLM.Message] {
  struct Request: Encodable {
    let model: String
    let messages: [ChatOpenAILLM.Message]
    let temperature: Double
    let n: Int
  }
  struct Response: Decodable {
    let choices: [Choice]
  }
  struct Choice: Decodable {
    let message: ChatOpenAILLM.Message
  }
  let data = try await post(
    to: "https://api.openai.com/v1/chat/completions", 
    request: Request(
      model: model, 
      messages: messages, 
      temperature: temperature,
      n: variants
    ), 
    headers: ["Authorization": "Bearer \(apiKey)"]
  )
  return try JSONDecoder().decode(Response.self, from: data)
    .choices
    .map { $0.message }
}

func completion(
  model: String,
  temperature: Double,
  variants: Int,
  prompt: String,
  apiKey: String
) async throws -> [String] {
  struct Request: Encodable {
    let model: String
    let prompt: String
    let temperature: Double
    let n: Int
  }
//  return try await call(
//    api: "https://api.openai.com/v1/completions", 
//    request: Request(
//      model: model, 
//      prompt: prompt, 
//      temperature: temperature, 
//      n: variants
//    ), 
//    apiKey: apiKey
//  )
  fatalError()
}
