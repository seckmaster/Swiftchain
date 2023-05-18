//
//  Memory.swift
//  
//
//  Created by Toni K. Turk on 18/05/2023.
//

import Foundation

/// A protocol that represents a memory storage interface for Large Language Models (LLM).
///
/// It defines methods for saving and loading memory, as well as clearing the memory.
public protocol Memory<LLMOutput, MemoryOutput> {
  associatedtype LLMOutput
  associatedtype MemoryOutput
  
  /// The key that uniquely identifies the memory variable.
  var memoryVariableKey: String { get }
  
  /// Clears the memory.
  mutating func clear()
  
  /// Saves an output to memory.
  ///
  /// - Parameter output: The output of the LLM to save.
  mutating func save(output: LLMOutput)
  
  /// Loads the memory contents.
  ///
  /// - Throws: If the loading operation fails.
  /// - Returns: The memory content.
  func load() throws -> MemoryOutput
}

/// A structure that provides a conversation memory implementation of the `Memory` protocol.
///
/// - Parameters:
///   - ChatMessage: The type of the conversation messages stored in the memory.
///   - MemoryOutput: The type of the memory output after serialization.
public struct ConversationMemory<ChatMessage, MemoryOutput>: Memory {
  public typealias LLMOutput = ChatMessage
  public typealias Serializer = ([LLMOutput]) throws -> MemoryOutput
  
  public var memoryVariableKey: String
  let serializer: Serializer
  private var memory: [LLMOutput] = []
  
  /// Initializes a new `ConversationMemory` instance with a given memory variable key and a serializer function.
  public init(
    memoryVariableKey: String,
    serializer: @escaping Serializer
  ) {
    self.memoryVariableKey = memoryVariableKey
    self.serializer = serializer
  }
  
  /// Initializes a new `ConversationMemory` instance with a serializer function.
  /// The memory variable key is set to "memory".
  public init(
    serializer: @escaping Serializer
  ) {
    self.memoryVariableKey = "memory"
    self.serializer = serializer
  }
  
  /// Clears the memory.
  mutating public func clear() {
    memory.removeAll()
  }
  
  /// Saves a conversation message to the memory.
  ///
  /// - Parameter output: The conversation message to save.
  mutating public func save(output: LLMOutput) {
    memory.append(output)
  }
  
  /// Loads the memory content and serializes it to `MemoryOutput`.
  ///
  /// - Throws: If the serialization operation fails.
  /// - Returns: The serialized memory content.
  public func load() throws -> MemoryOutput {
    try serializer(memory)
  }
}

/// An extension of `ConversationMemory` for when the `LLMOutput` is `Encodable` and the `MemoryOutput` is `String`.
public extension ConversationMemory where LLMOutput: Encodable, MemoryOutput == String {
  /// Initializes a new `ConversationMemory` instance with a memory variable key and a serializer function.
  /// The serializer function defaults to encoding to a JSON string.
  init(
    memoryVariableKey: String,
    serializer: @escaping Serializer = JSONEncoder().encodeToString
  ) {
    self.memoryVariableKey = memoryVariableKey
    self.serializer = serializer
  }
  
  /// Initializes a new `ConversationMemory` instance with a serializer function.
  /// The memory variable key is set to "memory".
  /// The serializer function defaults to encoding to a JSON string.
  init(
    serializer: @escaping Serializer = JSONEncoder().encodeToString
  ) {
    self.memoryVariableKey = "memory"
    self.serializer = serializer
  }
}

/// An extension of `JSONEncoder` that provides a method for encoding to a string.
public extension JSONEncoder {
  /// Encodes an `Encodable` object to a JSON string.
  ///
  /// - Parameter encodable: The `Encodable` object to encode.
  /// - Throws: If the encoding operation fails.
  /// - Returns: The JSON string.
  func encodeToString(_ encodable: Encodable) throws -> String {
    String(data: try encode(encodable), encoding: .utf8)!
  }
}
