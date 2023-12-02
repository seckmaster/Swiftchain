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
  responseFormat: AudioFormat = .mp3,
  speed: Double = 1.0,
  apiKey: String
) async throws -> Data {
  struct Request: Encodable {
    let model: String
    let input: String
    let voice: Voice
    let responseFormat: AudioFormat
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

public enum TranscriptionOutputFormat: String, Codable {
  case json, text, srt, verboseJson = "verbose_json", vtt
}

public func transcription(
  fileName: String,
  audioData: Data,
  model: String = "whisper-1",
  languageCode: String? = nil, // ISO-693-1 code: english = "en", slovenian = "sl"
//  prompt: String? = nil,
//  responseFormat: TranscriptionOutputFormat? = nil,
//  temperature: Double? = 0.2,
  apiKey: String
) async throws -> String {
  var data = Data()
  data.reserveCapacity(audioData.count + 1024)
  
  let boundary = UUID().uuidString
  
  data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
  data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
  data.append(model.data(using: .utf8)!)
  
  data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
  data.append("Content-Disposition: form-data; name=\"file\"; filename=\(fileName)\r\n".data(using: .utf8)!)
  data.append("Content-Type: audio/\(fileName.split(separator: ".")[1])\r\n\r\n".data(using: .utf8)!)
  data.append(audioData)
  body.append("\r\n".data(using: .utf8)!)
  
  body.append("--\(boundary)\r\n".data(using: .utf8)!)
  body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
  body.append("\(model)\r\n".data(using: .utf8)!)
  
  // Append the language
  if let languageCode {
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
    body.append("\(languageCode)\r\n".data(using: .utf8)!)
  }
  
  data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
  
  struct Response: Decodable {
    let text: String
  }
  let response: Response = try await post(
    to: "https://api.openai.com/v1/audio/transcriptions",
    binaryStream: data,
    headers: [
      "Authorization": "Bearer \(apiKey)",
      "OpenAI-Beta": "assistants=v1",
      "Content-Type": "multipart/form-data; boundary=\(boundary)",
    ],
    decoder: decoder
  )
  return response.text
}
