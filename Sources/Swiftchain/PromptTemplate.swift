//
//  PromptTemplate.swift
//  
//
//  Created by Toni K. Turk on 17/05/2023.
//

import Foundation

/// A protocol representing a callable template for LLM prompts.
///
/// This protocol uses Swift's @dynamicCallable attribute to create flexible and readable prompt templates.
public protocol PromptTemplateConforming<Prompt> {
  associatedtype Prompt
  
  /// Regular expression used to match variables in the prompt template.
  var variableRegex: Regex<(Substring, Substring)> { get }
  
  /// The template string that forms the basis of the prompt.
  var template: String { get }
  
  /// The variables identified in the template.
  var variables: [Substring] { get }
  
  /// Formats the prompt using provided arguments.
  func format(arguments: [String: String]) -> Prompt
  
  /// Formats the prompt using provided arguments, with `KeyValuePairs`.
  func format(arguments: KeyValuePairs<String, String>) -> Prompt
  
  /// Encodes an input into a suitable format for the LLM.
  func encode(input: String) -> Prompt
  
  /// Invokes a dynamic call to the template with keyword arguments.
  func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, String>) -> Prompt
}

/// Default implementations for `PromptTemplateConforming` protocol.
public extension PromptTemplateConforming {
  /// Formats the prompt using provided arguments, with `KeyValuePairs`.
  func format(arguments: KeyValuePairs<String, String>) -> Prompt {
    format(arguments: arguments.reduce(into: [:]) { $0[$1.key] = $1.value })
  }
  
  /// Invokes a dynamic call to the template with keyword arguments.
  func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, String>) -> Prompt {
    format(arguments: args)
  }
}

/// A structure conforming to `PromptTemplateConforming` that uses string prompts.
@dynamicCallable
public struct PromptTemplate: PromptTemplateConforming {
  public typealias Prompt = String
  public typealias Regex = _StringProcessing.Regex<(Substring, Substring)>
  
  public let variableRegex: Regex
  public let template: String
  public let variables: [Substring]
  
  /// Initializes a new `PromptTemplate`.
  ///
  /// - Parameters:
  ///   - variableRegex: The regex for matching variables in the template.
  ///   - template: The template string.
  public init(variableRegex: Regex, template: String) {
    self.variableRegex = variableRegex
    self.template = template
    self.variables = template.matches(of: variableRegex).map { $0.output.1 }
  }
  
  /// Formats the template using provided arguments.
  ///
  /// - Parameter arguments: The arguments for replacing variables in the template.
  /// - Returns: The formatted string.
  public func format(
    arguments: [String: String]
  ) -> String {
    var formatedPrompt = template
    var prevFailedMatch: Range<String.Index>?
    while true {
      let idx = prevFailedMatch.map { $0.upperBound } ?? formatedPrompt.startIndex
      guard let match = formatedPrompt[idx...].firstMatch(of: variableRegex) else { 
        break
      }
      
      guard let value = arguments[String(match.output.1)] else {
        // TODO: - Throw error?
        logger.warning("No value provided for variable: \(match.output.1)")
        prevFailedMatch = match.range
        continue
      }
      formatedPrompt.replaceSubrange(
        match.range, 
        with: value
      )
    }
    return formatedPrompt
  }
  
  /// Encodes an input into a suitable format for the LLM.
  ///
  /// - Parameter input: The string input to encode.
  /// - Returns: The encoded string.
  public func encode(input: String) -> String {
    input
  }
}

/// A structure for adapting the `PromptTemplateConforming` type to another prompt type.
public struct PromptTemplateAdapter<T: PromptTemplateConforming, Prompt>: PromptTemplateConforming {
  /// The original prompt template to be adapted.
  public let promptTemplate: T
  
  /// The adaptation function.
  public let adapter: (T.Prompt) -> Prompt
  
  /// Initializes a new `PromptTemplateAdapter`.
  ///
  /// - Parameters:
  ///   - promptTemplate: The original prompt template to adapt.
  ///   - adapter: The function for adapting the original prompt to a new prompt type.
  public init(promptTemplate: T, adapter: @escaping (T.Prompt) -> Prompt) {
    self.promptTemplate = promptTemplate
    self.adapter = adapter
  }
  
  /// The regex used to identify variables in the template.
  public var variableRegex: Regex<(Substring, Substring)> {
    promptTemplate.variableRegex
  }
  
  /// The underlying string of the prompt template.
  public var template: String {
    promptTemplate.template
  }
  
  /// The variables identified in the prompt template.
  public var variables: [Substring] {
    promptTemplate.variables
  }
  
  /// Formats the original prompt using provided arguments and adapts it to a new prompt type.
  ///
  /// - Parameter arguments: The arguments for replacing variables in the original template.
  /// - Returns: The adapted formatted prompt.
  public func format(arguments: [String : String]) -> Prompt {
    adapter(promptTemplate.format(arguments: arguments))
  }
  
  /// Encodes an input into a suitable format for the LLM and adapts it to a new prompt type.
  ///
  /// - Parameter input: The string input to encode.
  /// - Returns: The adapted encoded prompt.
  public func encode(input: String) -> Prompt {
    adapter(promptTemplate.encode(input: input))
  }
}
