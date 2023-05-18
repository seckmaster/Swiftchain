//
//  Memory.swift
//  
//
//  Created by Toni K. Turk on 18/05/2023.
//

import Foundation

public protocol Memory<LLMOutput, MemoryOutput> {
  associatedtype LLMOutput
  associatedtype MemoryOutput
  
  var memoryVariableKey: String { get }
  
  mutating func clear()
  mutating func save(output: LLMOutput)
  func load() throws -> MemoryOutput
}

public struct ConversationMemory<ChatMessage, MemoryOutput>: Memory {
  public typealias LLMOutput = ChatMessage
  public typealias Serializer = ([LLMOutput]) throws -> MemoryOutput
  
  public var memoryVariableKey: String
  let serializer: Serializer
  private var memory: [LLMOutput] = []
  
  public init(
    memoryVariableKey: String,
    serializer: @escaping Serializer
  ) {
    self.memoryVariableKey = memoryVariableKey
    self.serializer = serializer
  }
  
  public init(
    serializer: @escaping Serializer
  ) {
    self.memoryVariableKey = "memory"
    self.serializer = serializer
  }
  
  mutating public func clear() {
    memory.removeAll()
  }
  
  mutating public func save(output: LLMOutput) {
    memory.append(output)
  }
  
  public func load() throws -> MemoryOutput {
    try serializer(memory)
  }
}

public extension ConversationMemory where LLMOutput: Encodable, MemoryOutput == String {
  init(
    memoryVariableKey: String,
    serializer: @escaping Serializer = JSONEncoder().encodeToString
  ) {
    self.memoryVariableKey = memoryVariableKey
    self.serializer = serializer
  }
  
  init(
    serializer: @escaping Serializer = JSONEncoder().encodeToString
  ) {
    self.memoryVariableKey = "memory"
    self.serializer = serializer
  }
}

public extension JSONEncoder {
  func encodeToString(_ encodable: Encodable) throws -> String {
    String(data: try encode(encodable), encoding: .utf8)!
  }
}
