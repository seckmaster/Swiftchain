//
//  Common.swift
//  
//
//  Created by Toni K. Turk on 12. 11. 23.
//

import Foundation

extension [String: String] {
  static func header(apiKey: String) -> Element {
    ("Authorization", "Bearer \(apiKey)")
  }
}

let encoder: JSONEncoder = {
  let encoder = JSONEncoder()
  encoder.keyEncodingStrategy = .convertToSnakeCase
  return encoder
}()

let decoder: JSONDecoder = {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  return decoder
}()

struct List<T> {
  let data: [T]
}

extension List: Encodable where T: Encodable {} 
extension List: Decodable where T: Decodable {}
