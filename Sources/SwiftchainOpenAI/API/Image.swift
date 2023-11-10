//
//  Image.swift
//  
//
//  Created by Toni K. Turk on 9. 11. 23.
//

import Foundation
import Swiftchain

// https://platform.openai.com/docs/api-reference/images

public enum ImageQuality: String, Codable {
  case standard
  case hd
}

public enum ImageResponseFormat: String, Codable {
  case url
  case b64
}

public enum ImageStyle: String, Codable {
  case vivid
  case natural
}

public struct ImageResponse: Decodable {
  let url: URL?
  let b64Json: Data?
}

public func createImage(
  prompt: String,
  model: String? = nil,
  n: Int? = nil, // 1..10 (for dall-e-3, must be 1)
  quality: ImageQuality? = nil,
  responseFormat: ImageResponseFormat? = nil,
  size: String? = nil,
  style: ImageStyle? = nil,
  apiKey: String
) async throws -> [ImageResponse] {
  struct Request: Encodable {
    let prompt: String
    let model: String?
    let n: Int?
    let quality: ImageQuality?
    let responseFormat: ImageResponseFormat?
    let size: String?
    let style: ImageStyle?
  }
  struct Response: Decodable {
    let data: [ImageResponse]
  }
  let encoder = JSONEncoder()
  encoder.keyEncodingStrategy = .convertToSnakeCase
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  let response: Response = try await post(
    to: "https://api.openai.com/v1/audio/speech", 
    request: Request(
      prompt: prompt, 
      model: model, 
      n: n, 
      quality: quality, 
      responseFormat: responseFormat, 
      size: size, 
      style: style
    ),
    headers: ["Authorization": "Bearer \(apiKey)"],
    encoder: encoder,
    decoder: decoder
  )
  return response.data
}
