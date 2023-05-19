//
//  LLM.swift
//  
//
//  Created by Toni K. Turk on 17/05/2023.
//

import Foundation

/// A protocol representing a generic Large Language Model (LLM).
///
/// `Input` and `Output` are associated types, representing the input and output types of the LLM respectively.
public protocol LLM<Input, Output> {
  associatedtype Input
  associatedtype Output
  
  /// Triggers the LLM using a provided request.
  ///
  /// - Parameter request: The input to the LLM.
  /// - Throws: If an error occurs during the invocation.
  /// - Returns: The output from the LLM.
  func invoke(_ request: Input) async throws -> Output
}

/// A structure for modifying the input and output of a given LLM.
///
/// `Input` and `Output` are the types of the input and output data respectively. `LLM` represents the LLM being modified.
public struct LLMIOModifier<Input, Output, LLM: Swiftchain.LLM>: Swiftchain.LLM {
  public let llm: LLM
  public let inputModifier: (Input) -> LLM.Input
  public let outputModifier: (LLM.Output) -> Output
  
  /// Creates a new instance of `LLMIOModifier`.
  ///
  /// - Parameters:
  ///   - llm: The LLM to be modified.
  ///   - inputModifier: A closure that transforms the input data.
  ///   - outputModifier: A closure that transforms the output data.
  public init(
    llm: LLM,
    inputModifier: @escaping (Input) -> LLM.Input,
    outputModifier: @escaping (LLM.Output) -> Output
  ) {
    self.llm = llm
    self.inputModifier = inputModifier
    self.outputModifier = outputModifier
  }
  
  /// Triggers the LLM with the modified input and then modifies its output.
  ///
  /// - Parameter request: The input to the LLM.
  /// - Throws: If an error occurs during the invocation.
  /// - Returns: The modified output from the LLM.
  public func invoke(_ request: Input) async throws -> Output {
    let out = try await llm.invoke(inputModifier(request))
    return outputModifier(out)
  }
}

/// A structure for modifying the input of a given LLM.
///
/// `Input` is the type of the input data. `LLM` represents the LLM being modified.
public struct LLMIModifier<Input, LLM: Swiftchain.LLM>: Swiftchain.LLM {
  public let llm: LLM
  public let inputModifier: (Input) -> LLM.Input
  
  /// Creates a new instance of `LLMIModifier`.
  ///
  /// - Parameters:
  ///   - llm: The LLM to be modified.
  ///   - inputModifier: A closure that transforms the input data.
  public init(
    llm: LLM,
    inputModifier: @escaping (Input) -> LLM.Input
  ) {
    self.llm = llm
    self.inputModifier = inputModifier
  }
  
  /// Triggers the LLM with the modified input.
  ///
  /// - Parameter request: The input to the LLM.
  /// - Throws: If an error occurs during the invocation.
  /// - Returns: The output from the LLM.
  public func invoke(_ request: Input) async throws -> LLM.Output {
    try await llm.invoke(inputModifier(request))
  }
}

/// A structure for modifying the output of a given LLM.
///
/// `Output` is the type of the output data. `LLM` represents the LLM being modified.
public struct LLMOModifier<Output, LLM: Swiftchain.LLM>: Swiftchain.LLM {
  public let llm: LLM
  public let outputModifier: (LLM.Output) -> Output
  
  /// Creates a new instance of `LLMOModifier`.
  ///
  /// - Parameters:
  ///   - llm: The LLM to be modified.
  ///   - outputModifier: A closure that transforms the output data.
  public init(
    llm: LLM,
    outputModifier: @escaping (LLM.Output) -> Output
  ) {
    self.llm = llm
    self.outputModifier = outputModifier
  }
  
  /// Triggers the LLM and then modifies its output.
  ///
  /// - Parameter request: The input to the LLM.
  /// - Throws: If an error occurs during the invocation.
  /// - Returns: The modified output from the LLM.
  public func invoke(_ request: LLM.Input) async throws -> Output {
    let out = try await llm.invoke(request)
    return outputModifier(out)
  }
}
