//
//  API.swift
//  
//
//  Created by Toni K. Turk on 17/05/2023.
//

import Swiftchain
import Foundation

public func chat(
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
    let finishReason: FinishReason?
  }
  enum FinishReason: String, Decodable {
    case stop, length, contentFilter
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
  do {
    return try JSONDecoder().decode(Response.self, from: data)
      .choices
      .map { $0.message }
  } catch {
    logger.error(.init(stringLiteral: "Request to OpenAI failed. Response:\n"+(String(data: data, encoding: .utf8) ?? "<no text>")))
    throw error
  }
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

public func embedding(
  model: String = "text-embedding-ada-002",
  input: String,
  apiKey: String
) async throws -> [Double] {
  struct Request: Encodable {
    let model: String
    let input: String
  }
  struct Response: Decodable {
    let data: [ResponseData]
  }
  struct ResponseData: Decodable {
    let embedding: [Double]
  }
  let data = try await post(
    to: "https://api.openai.com/v1/embeddings", 
    request: Request(
      model: model, 
      input: input
    ), 
    headers: ["Authorization": "Bearer \(apiKey)"]
  )
  do {
    return try JSONDecoder().decode(Response.self, from: data).data.first!.embedding
  } catch {
    logger.error(.init(stringLiteral: "Request to OpenAI failed. Response:\n"+(String(data: data, encoding: .utf8) ?? "<no text>")))
    throw error
  }
}
