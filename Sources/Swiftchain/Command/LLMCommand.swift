//
//  LLMCommand.swift
//  
//
//  Created by Toni K. Turk on 22/05/2023.
//

import Foundation

public protocol LLMCommand {
  func call(_ args: [String: String]) async throws -> String
  
  var name: String { get }
  var description: String { get }
  var inputSchema: String { get }
  
  var promptDescription: String { get }
}

public extension LLMCommand {
  var promptDescription: String {
    name + ": " + description + ". args JSON schema: " + inputSchema 
  }
}
