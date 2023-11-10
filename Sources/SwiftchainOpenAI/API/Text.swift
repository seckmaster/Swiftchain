//
//  Text.swift
//  
//
//  Created by Toni K. Turk on 9. 11. 23.
//

import Foundation
import Swiftchain

public func chat(
  model: String,
  temperature: Double,
  variants: Int,
  messages: ChatOpenAILLM.Messages,
  functions: [ChatOpenAILLM.Function]?,
  apiKey: String
) async throws -> [ChatOpenAILLM.Message] {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  let response: Response = try await post(
    to: "https://api.openai.com/v1/chat/completions", 
    request: Request(
      model: model, 
      messages: messages,
      functions: functions,
      temperature: temperature,
      n: variants,
      stream: false
    ),
    headers: ["Authorization": "Bearer \(apiKey)"],
    decoder: decoder
  )
  return response
    .choices
    .map { $0.message }
}

public func streamChat(
  model: String,
  temperature: Double,
  variants: Int,
  messages: ChatOpenAILLM.Messages,
  functions: [ChatOpenAILLM.Function]?,
  apiKey: String
) throws -> any AsyncSequence {
  let stream = try streamPost(
    to: "https://api.openai.com/v1/chat/completions", 
    request: Request(
      model: model, 
      messages: messages,
      functions: functions,
      temperature: temperature,
      n: variants,
      stream: true
    ),
    headers: ["Authorization": "Bearer \(apiKey)"]
  )
  struct Choices: Decodable {
    struct Choice: Decodable {
      let delta: ChatOpenAILLM.Message
      let finishReason: FinishReason?
    }
    let choices: [Choice]
  }
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  let doneData = "[DONE]\n\n".data(using: .utf8)!
  return stream.map { data in
    do {
      let string = String(data: data, encoding: .utf8)!
      let chunks = string.split(separator: "data: ")
      return try chunks
        .map { String($0).data(using: .utf8)! }
        .flatMap { 
          do {
            if $0 == doneData {
              return [ChatOpenAILLM.Message]()
            }
            let choices = try decoder.decode(Choices.self, from: $0)
            var messages = [ChatOpenAILLM.Message]()
            for choice in choices.choices {
              if choice.finishReason != nil {
                break
              } else {
                messages.append(choice.delta)
              }
            }
            return messages
          } catch {
            throw error
          }
        }
    } catch {
      logger.error(.init(stringLiteral: "Request to OpenAI failed. Response:\n"+(String(data: data, encoding: .utf8) ?? "<no text>")))
      throw error
    }
  }
}

private struct Request: Encodable {
  let model: String
  let messages: [ChatOpenAILLM.Message]
  let functions: [ChatOpenAILLM.Function]?
  let temperature: Double
  let n: Int
  let stream: Bool
}

private struct Response: Decodable {
  let choices: [Choice]
}

private struct Choice: Decodable {
  let message: ChatOpenAILLM.Message
  let finishReason: FinishReason?
}

private enum FinishReason: String, Decodable {
  case stop, length, contentFilter = "content_filter", functionCall = "function_call"
}
