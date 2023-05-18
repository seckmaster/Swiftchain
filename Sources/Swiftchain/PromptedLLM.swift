//
//  PromptedLLM.swift
//  
//
//  Created by Toni K. Turk on 18/05/2023.
//

import Foundation

public protocol PromptedLLM<Memory, LLM, PromptTemplate> {
  associatedtype Memory: Swiftchain.Memory
  associatedtype LLM: Swiftchain.LLM
  associatedtype PromptTemplate: Swiftchain.PromptTemplateConforming
  
  var promptTemplate: PromptTemplate { get }
  var memory: Memory { get }
  var llm: LLM { get }
  
  mutating func run(args: [String: String]) async throws -> Memory.LLMOutput
}

public struct ConversationalLLM<
    LLM: Swiftchain.LLM, 
    Memory: Swiftchain.Memory, 
    PromptTemplate: PromptTemplateConforming
>: PromptedLLM where PromptTemplate.Prompt == LLM.Input, Memory.MemoryOutput == String, LLM.Output == Memory.LLMOutput, Memory.LLMOutput == PromptTemplate.Prompt {
  public let promptTemplate: PromptTemplate
  public private(set) var memory: Memory
  public let llm: LLM
  public let inputVariableKey: String
   
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
      throw NSError() // TODO: - throw a nice error!
    }
    guard promptTemplate.variables.contains(where: { $0 == inputVariableKey }) else {
      throw NSError() // TODO: - throw a nice error!
    }
  }
  
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
