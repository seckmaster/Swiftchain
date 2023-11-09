//
//  Sound.swift
//  
//
//  Created by Toni K. Turk on 9. 11. 23.
//

import Swiftchain
import Foundation

// https://platform.openai.com/docs/api-reference/audio/createSpeech

public enum Voice: String, Codable {
  case alloy
  case echo
  case fable
  case onyx
  case nova
  case shimmer
}

public enum AudioFormat: String, Codable {
  case mp3
  case opus
  case aac
  case flac
}

public func speech(
  model: String,
  input: String,
  voice: Voice,
  responseFormat: String = "mp3",
  speed: Double = 1.0,
  apiKey: String
) async throws -> Data {
  struct Request: Encodable {
    let model: String
    let input: String
    let voice: Voice
    let responseFormat: String
    let speed: Double
  }
  return try await post(
    to: "https://api.openai.com/v1/audio/speech", 
    request: Request(
      model: model, 
      input: input, 
      voice: voice, 
      responseFormat: responseFormat, 
      speed: speed
    ),
    headers: ["Authorization": "Bearer \(apiKey)"]
  )
}

//public func transcription(
//  
//) async throws -> String {
//  
//}
