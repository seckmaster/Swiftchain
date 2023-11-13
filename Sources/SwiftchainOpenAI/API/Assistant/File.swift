//
//  File.swift
//  
//
//  Created by Toni K. Turk on 12. 11. 23.
//

import Foundation
import Swiftchain

public struct File: Codable, Identifiable {
  public var id: String
  public var bytes: UInt
  public var createdAt: Date
  public var filename: String
  public var object: String = "file"
  public var purpose: Purpose
  
  public enum Purpose: String, Codable {
    case fineTune = "fine-tune"
    case fineTuneResults = "fine-tune-results"
    case assistants = "assistants"
    case assistantsOutput = "assistants_output"
  }
}

public func listFiles(
  purpose: File.Purpose? = nil,
  apiKey: String
) async throws -> [File] {
  try await get(
    to: .init(string: "https://api.openai.com/v1/files" + (purpose.map { "?purpose="+$0.rawValue } ?? ""))!, 
    headers: [
      "Authorization": "Bearer \(apiKey)",
      "OpenAI-Beta": "assistants=v1",
    ],
    decode: List<File>.self,
    decoder: decoder
  ).data
}

public func uploadFile(
  fileName: String,
  base64EncodedData file: Data, // max 512MB
  purpose: File.Purpose,
  apiKey: String
) async throws -> File {
  var data = Data()
  data.reserveCapacity(file.count)
  
  let boundary = UUID().uuidString
  
  data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
  data.append("Content-Disposition: form-data; name=\"purpose\"\r\n\r\n".data(using: .utf8)!)
  data.append(purpose.rawValue.data(using: .utf8)!)
  
  data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
  data.append("Content-Disposition: form-data; name=\"file\"; filename=\(fileName)\r\n".data(using: .utf8)!)
  data.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
  data.append(file)
  data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
  
  return try await post(
    to: "https://api.openai.com/v1/files",
    binaryStream: data,
    headers: [
      "Authorization": "Bearer \(apiKey)",
      "OpenAI-Beta": "assistants=v1",
      "Content-Type": "multipart/form-data; boundary=\(boundary)",
    ],
    decoder: decoder
  )
}

public func file(
  fileId: File.ID,
  apiKey: String
) async throws -> File {
  try await get(
    to: .init(string: "https://api.openai.com/v1/files/\(fileId)")!,
    headers: [
      "Authorization": "Bearer \(apiKey)",
      "OpenAI-Beta": "assistants=v1",
    ]
  )
}

public func fileContent(
  fileId: File.ID,
  apiKey: String
) async throws -> Data {
  try await get(
    to: .init(string: "https://api.openai.com/v1/files/\(fileId)/content")!,
    headers: [
      "Authorization": "Bearer \(apiKey)",
      "OpenAI-Beta": "assistants=v1",
    ]
  )
}
