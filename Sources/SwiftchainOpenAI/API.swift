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
) async throws -> [String] {
  struct Request: Encodable {
    let model: String
    let messages: [ChatOpenAILLM.Message]
    let temperature: Double
    let n: Int
  }
  return try await call(
    api: "https://api.openai.com/v1/chat/completions", 
    request: Request(
      model: model, 
      messages: messages, 
      temperature: temperature,
      n: variants
    ), 
    apiKey: apiKey
  )
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
  return try await call(
    api: "https://api.openai.com/v1/completions", 
    request: Request(
      model: model, 
      prompt: prompt, 
      temperature: temperature, 
      n: variants
    ), 
    apiKey: apiKey
  )
}

fileprivate func call<E: Encodable>(
  api url: URL,
  request: E,
  apiKey: String
) async throws -> [String] {
  let data = try await post(
    to: url, 
    request: request,
    headers: ["Authorization": "Bearer \(apiKey)"]
  )
  
  guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { 
    throw NSError()
  }
  return ((((json["choices"] as? [[String: Any]])?[0] as? [String: Any])?["message"] as? [String: Any])?["content"] as? String).map { [$0] } ?? []
}
