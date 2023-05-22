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

#### Chain of two conversational LLMs

The provided example implements a chain of two Large Language Models (LLMs), which communicate and collaborate to solve complex programming tasks based on user input.

**How it works*

Here's a quick overview of how the code works:
1. The script initializes two instances of the ChatOpenAILLM class, each representing a distinct Large Language Model.
2. It then defines two prompt templates. The first model takes the programming task you input and devises a strategy for solving the problem, while also modifying the input text to make it easier for the second model to process. The second model then takes the strategy and thought process from the first model and attempts to generate Python code for the task.
3. Each model is incorporated into a ConversationFlow, which manages the conversation between the two models and tracks the conversation history.
4. The script then creates an LLMChain that links the two models together. The LLMChain transforms the output of the first model to be used as input for the second model.
5. Finally, the script prompts you for a task input, then enters a loop where it uses the LLMChain to process the tasks in a queue. If the models generate additional tasks during processing, these are added to the queue for further processing. The loop continues until all tasks have been processed.

Remember, the performance of this script depends heavily on the capability of the models used and the complexity of the tasks given. Always ensure that your API Key is correct and that the models you are using are capable of handling the tasks provided.

**Code:**

```swift
  let llm1 = ChatOpenAILLM(
    apiKey: ProcessInfo.processInfo.environment["OPEN_AI_API_KEY"], 
    defaultTemperature: 1.0
  )
  
  let prompt1 = PromptTemplateAdapter(
    promptTemplate: PromptTemplate(
      variableRegex: .init {
        "{"
        Capture(OneOrMore(.word))
        "}"
      },
      template: """
    You are an expert in programming. Given a programming assignment, devise a strategy of solving the problem at hand. Provide you thoughts and strategy of solving it.
    Also modify the input text so that it will be easier to process by another LLM. 
    Your output will be provided to another LLM, such as yourself, which will generate the code. 
    
    Provide your output in valid JSON format!
    
    ### Example output:
    {
      "strategy": "... here goes the strategy of solving the problem",
      "thoughts": "... here are your thoughts on solving the problem",
      "task": "... here goes a modified textual description of the programming task"
    }
    
    History:
    {history}
    
    Conversation:
    Human: {input}
    AI: 
    """
    ), 
    adapter: {
      ChatOpenAILLM.Message(role: .user, content: $0)
    }
  )
  
  let conversationalLLM1 = try ConversationFlow(
    promptTemplate: prompt1, 
    memory: ConversationMemory<ChatOpenAILLM.Message, String>(memoryVariableKey: "history"), 
    llm: LLMIOModifier(
      llm: llm1,
      inputModifier: { [$0] },
      outputModifier: { $0.messages[0] }
    )
  )
  
  let llm2 = ChatOpenAILLM(
    apiKey: ProcessInfo.processInfo.environment["OPEN_AI_API_KEY"], 
    defaultTemperature: 1.0
  )
  
  let prompt2 = PromptTemplateAdapter(
    promptTemplate: PromptTemplate(
      variableRegex: .init {
        "{"
        Capture(OneOrMore(.word))
        "}"
      },
      template: """
    You are expert in programming. You will be given a strategy and thought process for solving a programming task. Your goal is to provide 
    functional code in Python. Make sure to make code readable, understandable and documented. You might not be able to complete all assignments 
    of a complex problem in one go. If that happens, output a list of tasks that still need to be implemented, as well as a strategy and thought
    processes involved in your reasoning. Those tasks will be forwarded to another LLM, just like you. 
    
    Provide your output in valid JSON format!
    
    You will receive input in the following form:
    
    ### Example input:
    {
      "strategy": "... here goes the strategy of solving the problem",
      "thoughts": "... here are your thoughts on solving the problem",
      "task": "... here goes a modified textual description of the programming task"
    }
    
    ### Example output:
    {
      "code": "here goes the generated python code",
      "todo": [
        {
          "strategy": "... here goes the strategy for solving the sub-task",
          "thoughts": "... here are your thoughts on the specific sub-task",
          "task": "... here goes a textual description of the sub-task that still needs to be done"
        }
      ]
    }
    
    History:
    {history}
    
    Conversation:
    LLM: {input}
    AI: 
    """
    ), 
    adapter: {
      ChatOpenAILLM.Message(role: .user, content: $0)
    }
  )
  
  struct Output: Codable {
    let code: String
    let todo: [Todo]
    
    struct Todo: Codable {
      let strategy: String
      let thoughts: String
      let task: String
    }
  }
  
  let conversationalLLM2 = try ConversationFlow(
    promptTemplate: prompt2,
    memory: ConversationMemory<ChatOpenAILLM.Message, String>(memoryVariableKey: "history"), 
    llm: LLMIOModifier(
      llm: llm2,
      inputModifier: { [$0] },
      outputModifier: { $0.messages[0] }
    )
  )
  
  var todoQueue: [Output.Todo] = []
  
  let chain = LLMChain(
    llm1: .init(conversationalLLM1), 
    llm2: .init(conversationalLLM2),
    transformOutput: {
      do {
        let todo = try JSONDecoder().decode(Output.Todo.self, from: $0.content.data(using: .utf8)!)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let prettyEncoded = String(data: try encoder.encode(todo), encoding: .utf8)!
        return ["input": prettyEncoded]
      } catch {
        print(error)
        throw error
      }
    }
  )
  
  print("Input a task:")
  todoQueue.append(.init(strategy: "", thoughts: "", task: readLine()!))
  
  while !todoQueue.isEmpty {
    let task = todoQueue.removeFirst()
    let result = try await chain.call(args: [
      "input": task.task
    ])
    
    let output = try JSONDecoder().decode(Output.self, from: result.content.data(using: .utf8)!)
    todoQueue.append(contentsOf: output.todo)
  }
```
