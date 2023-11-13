//
//  File.swift
//  
//
//  Created by Toni K. Turk on 12. 11. 23.
//

import Foundation
import Swiftchain

public struct File: Codable, Identifiable {
  public var id: String
  public var bytes: UInt
  public var createdAt: Date
  public var filename: String
  public var object: String = "file"
  public var purpose: Purpose
  
  public enum Purpose: String, Codable {
    case fineTune = "fine-tune"
    case fineTuneResults = "fine-tune-results"
    case assistants = "assistants"
    case assistantsOutput = "assistants_output"
  }
}
