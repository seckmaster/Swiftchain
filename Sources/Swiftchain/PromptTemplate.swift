//
//  PromptTemplate.swift
//  
//
//  Created by Toni K. Turk on 17/05/2023.
//

import Foundation

@dynamicCallable
public struct PromptTemplate {
  public typealias Regex = _StringProcessing.Regex<(Substring, variable: Substring)>
  
  public let variableRegex: Regex
  public let prompt: String
  public let variables: [Substring]
  
  public init(
    variableRegex: Regex,
    prompt: String
  ) {
    self.variableRegex = variableRegex
    self.prompt = prompt
    self.variables = prompt.matches(of: variableRegex)
      .map { $0.output.variable }
  }
}

public extension PromptTemplate {
  func format(
    arguments: [String: String]
  ) -> String {
    var formatedPrompt = prompt
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
  
  func format(
    arguments: KeyValuePairs<String, String>
  ) -> String {
    format(arguments: arguments.reduce(into: [:]) { $0[$1.key] = $1.value })
  }
  
  func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, String>) async throws -> String {
    format(arguments: args)
  }
}
