//
//  PromptedLLM.swift
//  
//
//  Created by Toni K. Turk on 18/05/2023.
//

import Foundation

/// `LLMFlow` is a protocol that represents a structured workflow for Large Language Model (LLM) applications.
///
/// This protocol defines a chain of operations for running an LLM with specific inputs and conditions. It encapsulates
/// key elements of the LLM operation, including memory handling, prompt formatting and the execution of the LLM itself.
///
/// The associated types `Memory`, `LLM`, and `PromptTemplate` provide flexible abstractions for handling
/// different needs of LLM applications.
///
/// `Memory`: An abstraction that represents the memory to be used by the LLM. This could include data that
/// needs to be remembered across multiple LLM invocations, such as conversation history or other contextual
/// data.
///
/// `LLM`: The Large Language Model to be used. This could be any model that fits the requirements for your use case,
/// such as GPT-3 or GPT-4.
///
/// `PromptTemplate`: An abstraction for a template that formats the LLM prompts. It could be designed to
/// handle different types of inputs and format them into a proper prompt for the LLM.
///
/// This protocol ensures a consistent method `run(args:)` that executes the LLM with specified arguments, while also
/// handling any error that may occur during the execution. The method returns the output of the LLM.
public protocol LLMFlow<Memory, LLM, PromptTemplate> {
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
