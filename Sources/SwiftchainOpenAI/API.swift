//
//  API.swift
//  
//
//  Created by Toni K. Turk on 17/05/2023.
//

import Swiftchain
import Foundation

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
