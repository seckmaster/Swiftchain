//
//  Logger.swift
//  
//
//  Created by Toni K. Turk on 17/05/2023.
//

import Logging
import Rainbow

public let logger = Logger(label: "com.swiftchain.logger", factory: LoggerBE.init)

struct LoggerBE: LogHandler {
  subscript(metadataKey _: String) -> Logging.Logger.Metadata.Value? {
    get {
      nil
    }
    set(newValue) {
    }
  }
  
  var metadata: Logging.Logger.Metadata = .init()
  var logLevel: Logging.Logger.Level = .debug
  var label: String
  
  init(label: String) {
    self.label = label
  }
  
  func log(
    level: Logger.Level,
    message: Logger.Message,
    metadata: Logger.Metadata?,
    source: String,
    file: String,
    function: String,
    line: UInt
  ) {
    let indent = 8
    var message = message.description
    var lines = message.split(separator: "\n")
    switch level {
    case .info:
      message = lines.map { $0.indented(indent).green }.joined(separator: "\n")
    case .debug:
      message = lines.map { $0.indented(indent).cyan }.joined(separator: "\n")
    case .error:
      message = lines.map { $0.indented(indent).red }.joined(separator: "\n")
    case .warning:
      message = lines.map { $0.indented(indent).yellow }.joined(separator: "\n")
    case _:
      break
    }
    
    print(message)
  }
}

extension StringProtocol {
  func indented(_ indent: Int) -> String {
    Array(repeating: " ", count: indent).joined() + self
  }
}
