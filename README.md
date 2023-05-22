# Swiftchain: Type-Safe Library for Large Language Models

[![Swift Version](https://img.shields.io/badge/swift-5.8-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Swiftchain is a type-safe, Swift-centric library designed to simplify working with Large Language Models (LLMs) like GPT-4 and others in real-world applications. 

## Features
- **Type-Safe**: Swiftchain makes extensive use of Swift's powerful type system to provide a safe and reliable interface for working with LLMs. Swiftchain leverages Swift's protocols, associated types, and other features to provide a compile-time guarantee that your code is safe.
- **Flexible & Modular**: Our protocols and associated types allow developers to easily extend the library, define their custom implementations or swap components without changing the core logic.
- **Asynchronous Support**: Swiftchain supports asynchronous operations out of the box. It utilizes Swift's native async/await syntax for clean and readable asynchronous code.
- **Focus on LLMs**: Our library provides high-level abstractions for working with LLMs. This allows developers to focus on their application logic rather than the details of interacting with LLMs.

## Getting Started
### Requirements
- Swift 5.8
- Swift Package Manager

### Installation
To include Swiftchain in your project, you can add the package as a dependency in your `Package.swift` file:

```swift
let package = Package(
  name: "YourProjectName",
  dependencies: [
    .package(url: "https://github.com/yourusername/Swiftchain.git", .upToNextMajor(from: "1.0.0"))
  ],
  targets: [
    .target(name: "YourTargetName", dependencies: ["Swiftchain"]),
  ]
)
```

### Examples


#### A simple chat-bot:

```swift
// Create an instance of the LLM with OpenAI's GPT-4 model and an API key.
let llm = ChatOpenAILLM(apiKey: "your api key")

// Create a prompt template with a conversation format that adapts its output to make
// it suitable for `ChatOpenAILLM`.
let prompt = PromptTemplateAdapter(
  promptTemplate: PromptTemplate(
    variableRegex: .init {
      "{"
      Capture(OneOrMore(.word))
      "}"
    },
    template: """
    You are a helpful assistant expert in programming.
    
    History:
    {history}
    
    Conversation:
    Human: {input}
    AI:
    """
  ),
  adapter: { ChatOpenAILLM.Message(role: .user, content: $0) }
)

// Create a conversational LLM flow using the defined LLM, memory and prompt template.
var conversationFlow = try ConversationFlow(
  promptTemplate: prompt, 
  memory: ConversationMemory<ChatOpenAILLM.Message, String>(memoryVariableKey: "history"), 
  llm: LLMIOModifier(
    llm: llm,
    inputModifier: { [$0] },
    outputModifier: { $0.messages[0] }
  )
)

// Use the conversational LLM in a loop, asking for user input and printing the model's response.
do {
  while true {
    let result = try await conversationFlow.run(args: [
      "input": readLine()!
    ])
    print(result.content)
  }
} catch {
  print(error)
}
```
