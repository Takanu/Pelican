//
//  Utilities.swift
//  kabuki
//
//  Created by Takanu Kyriako on 24/03/2017.
//
//

import Foundation
import Vapor
import Dispatch // Must be specified for Linux support

// This needs re-factoring ASAP.

internal func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
  var i = 0
  return AnyIterator {
    let next = withUnsafeBytes(of: &i) { $0.load(as: T.self) }
    if next.hashValue != i { return nil }
    i += 1
    return next
  }
}

internal class DispatchTimer {
  private let queue = DispatchQueue(label: "timer")
  private let interval: TimeInterval
  private let execute: () -> Void
  private var operation: DispatchWorkItem?
  
  init(interval: TimeInterval, execute: @escaping () -> Void) {
    self.interval = interval
    self.execute = execute
  }
  
  func start() {
    let operation = DispatchWorkItem { [weak self] in
      
      defer { self?.start() }
      self?.execute()
      
    }
    self.operation = operation
    queue.asyncAfter(deadline: .now() + interval, execute: operation)
  }
  func stop() {
    operation?.cancel()
  }
}

/// With Vapor 2 these are currently no longer necessary.
/*
// Extensions to manipulate node entries more seamlessly
extension Node {
  mutating func addNodeEntry(name: String, value: NodeConvertible) throws {
    var object = self.nodeObject
    if object != nil {
      object![name] = try value.makeNode()
      self = try object!.makeNode()
    }
  }
  
  mutating func removeNodeEntry(name: String) throws -> Bool {
    var object = self.nodeObject
    if object != nil {
      _ = object!.removeValue(forKey: name)
      self = try object!.makeNode()
      return true
    }
      
    else { return false }
  }
  
  mutating func renameNodeEntry(from: String, to: String) throws -> Bool {
    var object = self.nodeObject
    if object != nil {
      let value = object!.removeValue(forKey: from)
      object![to] = value
      self = try object!.makeNode()
      return true
    }
      
    else { return false }
  }
  
  mutating func removeNilValues() throws {
    var object = self.nodeObject
    if object != nil {
      for value in object! {
        
        if value.value.isNull == true {
          object!.removeValue(forKey: value.key)
        }
      }
      
      self = try object!.makeNode()
    }
  }
}
*/
