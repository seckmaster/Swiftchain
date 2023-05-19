//
//  ConversationFlow.swift
//  
//
//  Created by Toni K. Turk on 19/05/2023.
//

import Foundation

/// The `ConversationFlow` is an implementation of the `LLMFlow` protocol designed for conversational applications.
/// It chains together the handling of memory, prompt templating and running an LLM to simplify the interaction.
///
/// Here is an example of how to initialize and use a `ConversationFlow`:
///
///    ```swift
///    // Create an instance of the LLM with OpenAI's GPT-4 model and an API key.
///    let llm = ChatOpenAILLM(apiKey: "your api key")
///
///    // Create a prompt template adapter with a conversation format.
///    let prompt = PromptTemplateAdapter(
///      promptTemplate: PromptTemplate(
///        variableRegex: .init {
///          "{"
///          Capture(OneOrMore(.word))
///          "}"
///        },
///        template: """
///        You are a helpful assistant expert in programming.
///
///        History:
///        {history}
///
///        Conversation:
///        Human: {input}
///        AI:
///        """
///      ),
///      adapter: { ChatOpenAILLM.Message(role: .user, content: $0) }
///    )
///
///    // Create a conversational LLM using the defined LLM, memory and prompt template.
///    var conversationFlow = try ConversationFlow(
///      promptTemplate: prompt, 
///      memory: ConversationMemory<ChatOpenAILLM.Message, String>(memoryVariableKey: "history"), 
///      llm: LLMIOModifier(
///        llm: llm,
///        inputModifier: { [$0] },
///        outputModifier: { $0.messages[0] }
///      )
///    )
///
///    // Use the conversational LLM in a loop, asking for user input and printing the model's response.
///    do {
///      while true {
///        let result = try await conversationFlow.run(args: [
///          "input": readLine()!
///        ])
///        print(result.content)
///      }
///    } catch {
///      print(error)
///    }
///    ```
///
/// This example demonstrates a simple chatbot. It keeps a memory of the conversation history and
/// uses it to build a prompt for the LLM. The conversation continues indefinitely until an error occurs.
public struct ConversationFlow<
  LLM: Swiftchain.LLM,
  Memory: Swiftchain.Memory,
  PromptTemplate: Swiftchain.PromptTemplateConforming
>: LLMFlow where PromptTemplate.Prompt == LLM.Input, Memory.MemoryOutput == String, LLM.Output == Memory.LLMOutput, Memory.LLMOutput == PromptTemplate.Prompt {
  
  public let promptTemplate: PromptTemplate
  public private(set) var memory: Memory
  public let llm: LLM
  public let inputVariableKey: String
  
  /// Initializes a new `ConversationFlow` instance.
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
    //    logger.debug("Entering prompted LLM:")
    //    logger.debug(.init(stringLiteral: String(describing: prompt)))
    //    logger.debug("")
    let response = try await llm.invoke(prompt)
    memory.save(output: response)
    return response
  }
}
