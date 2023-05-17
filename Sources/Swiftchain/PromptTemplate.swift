//
//  PromptTemplate.swift
//  
//
//  Created by Toni K. Turk on 17/05/2023.
//

import Foundation

@dynamicCallable
public protocol PromptTemplateConforming<Prompt> where Prompt: Encodable {
  associatedtype Prompt
  
  var variableRegex: Regex<(Substring, variable: Substring)> { get }
  var template: String { get }
  var variables: [Substring] { get }
  
  func format(
    arguments: [String: String]
  ) -> Prompt
  
  func format(
    arguments: KeyValuePairs<String, String>
  ) -> Prompt
  
  func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, String>) -> Prompt
}

public extension PromptTemplateConforming {
  func format(
    arguments: KeyValuePairs<String, String>
  ) -> Prompt {
    format(arguments: arguments.reduce(into: [:]) { $0[$1.key] = $1.value })
  }
  
  func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, String>) -> Prompt {
    format(arguments: args)
  }
}

@dynamicCallable
public struct PromptTemplate: PromptTemplateConforming {
  public typealias Prompt = String
  public typealias Regex = _StringProcessing.Regex<(Substring, variable: Substring)>
  
  public let variableRegex: Regex
  public let template: String
  public let variables: [Substring]
  
  public init(
    variableRegex: Regex,
    template: String
  ) {
    self.variableRegex = variableRegex
    self.template = template
    self.variables = template.matches(of: variableRegex)
      .map { $0.output.variable }
  }
  
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
      
      guard let value = arguments[String(match.output.variable)] else {
        // TODO: - Throw error?
        logger.warning("No value provided for variable: \(match.output.variable)")
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
}

public struct PromptTemplateAdapter<T: PromptTemplateConforming, Prompt: Encodable>: PromptTemplateConforming {
  public let promptTemplate: T
  public let adapter: (T.Prompt) -> Prompt
  
  public init(
    promptTemplate: T,
    adapter: @escaping (T.Prompt) -> Prompt
  ) {
    self.promptTemplate = promptTemplate
    self.adapter = adapter
  }
  
  public var variableRegex: Regex<(Substring, variable: Substring)> {
    promptTemplate.variableRegex
  }
  
  public var template: String {
    promptTemplate.template
  }
  
  public var variables: [Substring] {
    promptTemplate.variables
  }
  
  public func format(arguments: [String : String]) -> Prompt {
    adapter(promptTemplate.format(arguments: arguments))
  }
}
