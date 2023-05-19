# Swiftchain: Type-Safe Library for Large Language Models

[![Swift Version](https://img.shields.io/badge/swift-5.1-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Swiftchain is a type-safe, Swift-centric library designed to simplify working with Large Language Models (LLMs) like GPT-4 and others in real-world applications. 

## Features
- **Type-Safe**: Swiftchain makes extensive use of Swift's powerful type system to provide a safe and reliable interface for working with LLMs. Swiftchain leverages Swift's protocols, associated types, and other features to provide a compile-time guarantee that your code is safe.
- **Flexible & Modular**: Our protocols and associated types allow developers to easily extend the library, define their custom implementations or swap components without changing the core logic.
- **Asynchronous Support**: Swiftchain supports asynchronous operations out of the box. It utilizes Swift's native async/await syntax for clean and readable asynchronous code.
- **Focus on LLMs**: Our library provides high-level abstractions for working with LLMs. This allows developers to focus on their application logic rather than the details of interacting with LLMs.

## Getting Started
### Requirements
- Swift 5.1 or later
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
