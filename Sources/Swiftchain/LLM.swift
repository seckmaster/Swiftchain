//
//  LLM.swift
//  
//
//  Created by Toni K. Turk on 17/05/2023.
//

import Foundation

public protocol LLM<Input, Output> {
  associatedtype Input
  associatedtype Output
  
  func invoke(_ request: Input) async throws -> Output
}

public struct LLMIOModifier<Input, Output, LLM: Swiftchain.LLM>: Swiftchain.LLM {
  public let llm: LLM
  public let inputModifier: (Input) -> LLM.Input
  public let outputModifier: (LLM.Output) -> Output
  
  public init(
    llm: LLM,
    inputModifier: @escaping (Input) -> LLM.Input,
    outputModifier: @escaping (LLM.Output) -> Output
  ) {
    self.llm = llm
    self.inputModifier = inputModifier
    self.outputModifier = outputModifier
  }
  
  public func invoke(_ request: Input) async throws -> Output {
    let out = try await llm.invoke(inputModifier(request))
    return outputModifier(out)
  }
}

public struct LLMIModifier<Input, LLM: Swiftchain.LLM>: Swiftchain.LLM {
  public let llm: LLM
  public let inputModifier: (Input) -> LLM.Input
  
  public init(
    llm: LLM,
    inputModifier: @escaping (Input) -> LLM.Input
  ) {
    self.llm = llm
    self.inputModifier = inputModifier
  }
  
  public func invoke(_ request: Input) async throws -> LLM.Output {
    try await llm.invoke(inputModifier(request))
  }
}

public struct LLMOModifier<Output, LLM: Swiftchain.LLM>: Swiftchain.LLM {
  public let llm: LLM
  public let outputModifier: (LLM.Output) -> Output
  
  public init(
    llm: LLM,
    outputModifier: @escaping (LLM.Output) -> Output
  ) {
    self.llm = llm
    self.outputModifier = outputModifier
  }
  
  public func invoke(_ request: LLM.Input) async throws -> Output {
    let out = try await llm.invoke(request)
    return outputModifier(out)
  }
}
