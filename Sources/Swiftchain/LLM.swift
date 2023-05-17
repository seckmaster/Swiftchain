//
//  LLM.swift
//  
//
//  Created by Toni K. Turk on 17/05/2023.
//

import Foundation

@dynamicCallable
public protocol LLM {
  func invoke(_ request: Encodable) async throws -> Decodable
  func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, String>) async throws -> Decodable
}

public extension LLM {
  func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, String>) async throws -> Decodable {
    guard let request = args.first(where: { $0.key == "request" })?.value else { throw NSError() }
    let encoded = try JSONEncoder().encode(request.data(using: .utf8))
    return try await invoke(encoded)
  }
}
