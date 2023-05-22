//
//  LLMChain.swift
//  
//
//  Created by Toni K. Turk on 19/05/2023.
//

import Foundation

/// A public structure representing a chain of two or more large language models (LLMs).
/// The structure is generic over two types, LLM1 and LLM2, which must conform to the LLMFlow protocol.
/// This structure allows chaining two LLMs together, passing the output of the first one to the input of the second one.
public struct LLMChain<LLM1: LLMFlow, LLM2: LLMFlow> {
  /// A typealias representing the asynchronous chaining of two LLMs.
  /// The chain takes an argument of type `LLM1.Args` and returns an output of type `LLM2.Output`.
  public typealias AsyncChain = (_ args: LLM1.Args) async throws -> LLM2.Output
  
  /// The chain of the two LLMs.
  private let chain: AsyncChain
  
  /// Creates a new instance of LLMChain.
  ///
  /// - Parameters:
  ///   - llm1: The first large language model (LLM1) boxed inside a `Box` type.
  ///   - llm2: The second large language model (LLM2) boxed inside a `Box` type.
  ///   - transformOutput: A closure that transforms the output of LLM1 into the input for LLM2.
  public init(
    llm1: Box<LLM1>,
    llm2: Box<LLM2>,
    transformOutput: @escaping (LLM1.Output) throws -> LLM2.Args
  ) {
    self.chain = {
      let llm1output = try await llm1.value.run(args: $0)
      return try await llm2.value.run(args: try transformOutput(llm1output))
    }
  }
  
  /// Creates a new instance of LLMChain using an existing chain.
  ///
  /// - Parameter chain: An asynchronous chain that takes an argument of type `LLM1.Args` and returns an output of type `LLM2.Output`.
  init(
    chain: @escaping AsyncChain
  ) {
    self.chain = chain
  }
  
  /// Calls the chain with the provided arguments.
  ///
  /// - Parameter args: Arguments of type `LLM1.Args` to pass into the chain.
  /// - Returns: The output of the chain of type `LLM2.Output`.
  public func call(args: LLM1.Args) async throws -> LLM2.Output {
    try await chain(args)
  }
}

public extension LLMChain {
  /// Composes the current LLMChain with another LLMFlow.
  ///
  /// - Parameter flow: The LLMFlow to compose with, boxed inside a `Box` type.
  /// - Returns: A new LLMChain with the first LLM being the original LLM1 and the second LLM being the passed LLMFlow.
  func compose<LLM3: LLMFlow>(
    flow: Box<LLM3>
  ) -> LLMChain<LLM1, LLM3> where LLM2.Output == LLM3.Args {
    .init(
      chain: {
        let llm2output = try await chain($0)
        return try await flow.value.run(args: llm2output)
      }
    )
  }
  
  /// Composes the current LLMChain with another LLMFlow.
  ///
  /// - Parameters:
  ///   - flow: The LLMFlow to compose with, boxed inside a `Box` type.
  ///   - transformOutput: A closure that transforms the output of the original LLMChain into the input for the new LLMFlow.
  /// - Returns: A new LLMChain with the first LLM being the original LLM1 and the second LLM being the passed LLMFlow.
  func compose<LLM3: LLMFlow>(
    flow: Box<LLM3>,
    transformOutput: @escaping (LLM2.Output) throws -> LLM3.Args
  ) -> LLMChain<LLM1, LLM3> {
    .init(
      chain: { args in
        let llm2Output = try await chain(args)
        return try await flow.value.run(args: try transformOutput(llm2Output))
      }
    )
  }
}

/// A class for boxing a value of a generic type `T`.
///
/// Boxing is a way to wrap a value in a class to leverage reference semantics.
public class Box<T> {
  
  /// The value of generic type `T` wrapped in the box.
  public var value: T
  
  /// Creates a new Box with the given value.
  ///
  /// - Parameter value: The value to box.
  public init(_ value: T) {
    self.value = value
  }
}
