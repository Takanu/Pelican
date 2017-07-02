//
//  ChatSessionFlood.swift
//  Pelican
//
//  Created by Takanu Kyriako on 27/03/2017.
//
//

import Foundation
import Vapor

// Used for creating groups of flood settings and keeping track of them.
public struct FloodLimit {
  private var floodLimit: Int = 0 // The number of messages it will accept before getting concerned.
  private var floodRange: Int = 0 // The time-frame that the flood limit and count applies to.
  private var floodCount: Int = 0 // The number of messages sent in the current window.
  private var floodRangeStart: Int = 0 // The starting time that the flood range applies to, in global time.
  
  var reachedLimit: Bool { return floodLimitHits >= breachLimit }
  private var floodLimitHits: Int = 0 // The number of times the limit has been hit
  private var breachLimit: Int = 0 // The number of times the limit can be hit before bad things happen.
  private var breachReset: Int = 0 // The time required for the breach limit to go down by one.
  private var breachResetStart: Int = 0 // The starting time that the reset applies to.
  
  // Initialises the flood limit type with a few settings
  public init(limit: Int, range: Int, breachLimit: Int, breachReset: Int) {
    self.floodLimit = limit
    self.floodRange = range
    self.breachLimit = breachLimit
    self.breachReset = breachReset
  }
  
  // Initialises it from another flood limit
  public init(clone: FloodLimit, withTime: Bool = false) {
    self.floodLimit = clone.floodLimit
    self.floodRange = clone.floodRange
    self.breachLimit = clone.breachLimit
    self.breachReset = clone.breachReset
    
    if withTime == true {
      self.floodCount = clone.floodCount
      self.floodRangeStart = clone.floodRangeStart
    }
    
  }
  
  // Increments the flood count, and returns whether or not this increment breached the flood limit.
  public mutating func bump(globalTime: Int) -> Bool {
    floodCount += 1
    
    // If we've hit the flood limit, increment the limit hits and set the flood and breach timers
    if floodCount >= floodLimit {
      floodLimitHits += 1
      floodCount = 0
      floodRangeStart = globalTime
      breachResetStart = globalTime
      return true
    }
    
    // If the flood range has been reached without flooding, reset the count
    if floodRangeStart <= globalTime - floodRange {
      floodCount = 0
      floodRangeStart = globalTime
    }
    
    // If the breach reset has been hit, reduce the breach hits by one to cool off the "alert" level.
    if breachResetStart <= globalTime - breachReset {
      if floodLimitHits > 0 { floodLimitHits -= 0 }
      floodRangeStart = globalTime
    }
    
    return false
  }
}
