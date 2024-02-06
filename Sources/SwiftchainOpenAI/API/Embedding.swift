//
//  Embedding.swift
//  
//
//  Created by Toni K. Turk on 10. 11. 23.
//

import Swiftchain
import Foundation

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
  let response: Response = try await post(
    to: "https://api.openai.com/v1/embeddings", 
    request: Request(
      model: model, 
      input: input
    ), 
    headers: ["Authorization": "Bearer \(apiKey)"]
  )
  return response.data.first!.embedding
}
