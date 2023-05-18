//
//  PromptedLLM.swift
//  
//
//  Created by Toni K. Turk on 18/05/2023.
//

import Foundation

/// A protocol that represents a prompted Large Language Model (LLM).
///
/// It defines methods for running the LLM with specific arguments.
public protocol PromptedLLM<Memory, LLM, PromptTemplate> {
  associatedtype Memory: Swiftchain.Memory
  associatedtype LLM: Swiftchain.LLM
  associatedtype PromptTemplate: Swiftchain.PromptTemplateConforming
  
  /// A template for formatting the LLM prompts.
  var promptTemplate: PromptTemplate { get }
  
  /// The memory used by the LLM.
  var memory: Memory { get }
  
  /// The LLM to be used.
  var llm: LLM { get }
  
  /// Executes the LLM with the specified arguments.
  ///
  /// - Parameter args: The arguments to be passed to the LLM.
  /// - Throws: If the execution fails.
  /// - Returns: The output of the LLM.
  mutating func run(args: [String: String]) async throws -> Memory.LLMOutput
}

/// A structure that provides a conversational LLM implementation of the `PromptedLLM` protocol.
public struct ConversationalLLM<
  LLM: Swiftchain.LLM,
  Memory: Swiftchain.Memory,
  PromptTemplate: Swiftchain.PromptTemplateConforming
>: PromptedLLM where PromptTemplate.Prompt == LLM.Input, Memory.MemoryOutput == String, LLM.Output == Memory.LLMOutput, Memory.LLMOutput == PromptTemplate.Prompt {
  
  public let promptTemplate: PromptTemplate
  public private(set) var memory: Memory
  public let llm: LLM
  public let inputVariableKey: String
  
  /// Initializes a new `ConversationalLLM` instance.
  ///
  /// - Parameters:
  ///   - promptTemplate: The template for formatting the LLM prompts.
  ///   - memory: The memory to be used by the LLM.
  ///   - llm: The LLM to be used.
  ///   - inputVariableKey: The key to identify the input variable.
  ///
  /// - Throws: If the initialization fails.
  public init(
    promptTemplate: PromptTemplate,
    memory: Memory,
    llm: LLM,
    inputVariableKey: String = "input"
  ) throws {
    self.promptTemplate = promptTemplate
    self.memory = memory
    self.llm = llm
    self.inputVariableKey = inputVariableKey
    guard promptTemplate.variables.contains(where: { $0 == memory.memoryVariableKey }) else {
      throw NSError() // TODO: - throw a specific error!
    }
    guard promptTemplate.variables.contains(where: { $0 == inputVariableKey }) else {
      throw NSError() // TODO: - throw a specific error!
    }
  }
  
  /// Executes the LLM with the specified arguments.
  ///
  /// - Parameter args: The arguments to be passed to the LLM.
  /// - Throws: If the execution fails.
  /// - Returns: The output of the LLM.
  public mutating func run(args: [String: String]) async throws -> Memory.LLMOutput {
    var args = args
    args[memory.memoryVariableKey] = try memory.load()
    memory.save(output: promptTemplate.encode(input: args[inputVariableKey]!))
    let prompt = promptTemplate.format(arguments: args)
    logger.debug("Entering prompted LLM:")
    logger.debug(.init(stringLiteral: String(describing: prompt)))
    logger.debug("")
    let response = try await llm.invoke(prompt)
    memory.save(output: response)
    return response
  }
}
