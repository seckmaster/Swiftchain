//
//  URLSessionHelper.swift
//  
//
//  Created by Toni K. Turk on 17/05/2023.
//

import Foundation

public func post<Request: Encodable>(
  to url: URL,
  request: Request,
  headers: [String: String],
  encoder: JSONEncoder = .init(),
  session: URLSession = .withLongTimeout
) async throws -> Data {
  var urlRequest = URLRequest(url: url)
  urlRequest.httpMethod = "POST"
  urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
  urlRequest.allHTTPHeaderFields = headers
  urlRequest.httpBody = try encoder.encode(request)
  let data = try await session.data(for: urlRequest).0
  return data
}

public func post<Request: Encodable, Response: Decodable>(
  to url: URL,
  request: Request,
  decode into: Response.Type,
  headers: [String: String],
  encoder: JSONEncoder = .init(),
  decoder: JSONDecoder = .init(),
  session: URLSession = .withLongTimeout
) async throws -> Response {
  let data = try await post(
    to: url, 
    request: request, 
    headers: headers, 
    encoder: encoder, 
    session: session
  )
  return try decoder.decode(into, from: data)
}

public extension URLSession {
  static var withLongTimeout: URLSession {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 600
    config.timeoutIntervalForResource = 600
    let session = URLSession(configuration: config)
    return session
  }
}

extension URL: ExpressibleByStringLiteral {
  public init(stringLiteral value: StringLiteralType) {
    self = .init(string: value)!
  }
}
