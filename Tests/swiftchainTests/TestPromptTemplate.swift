//
//  TestPromptTemplate.swift
//  
//
//  Created by Toni K. Turk on 17/05/2023.
//

import RegexBuilder
import XCTest
@testable import Swiftchain

final class TestPromptTemplate: XCTestCase {
  func testApply() {
    XCTAssertEqual(
      format(regex: .init { 
        "{"
        Capture(OneOrMore(.any))
        "}"
      }, prompt: "This is a simple prompt", arguments: [:]),
      "This is a simple prompt"
    )
  }
}

extension TestPromptTemplate {
  func format(regex: PromptTemplate.Regex, prompt: String, arguments: [String: String]) -> String {
    PromptTemplate(variableRegex: regex, template: prompt).format(arguments: arguments)
  } 
}
