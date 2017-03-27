//
//  SessionActions.swift
//  Pelican
//
//  Created by Takanu Kyriako on 27/03/2017.
//
//

import Foundation
import Vapor

// Defines a queued action for a specific session, to be run at a later date
class TelegramBotSessionAction {
  var name: String = ""           // Only used if the user may later want to find and remove the action before being played.
  var session: Session // The session to be affected
  var bot: Pelican
  var time: Int // The global time at which this should be executed
  var action: (Session) -> ()
  
  init(session: Session, bot: Pelican, delay: Int, action: @escaping (Session) -> (), name: String = "") {
    self.name = name
    self.session = session
    self.bot = bot
    self.time = bot.globalTimer + delay
    self.action = action
  }
  
  func execute() {
    action(session)
  }
  
  func changeTime(_ globalTime: Int) {
    time = globalTime
  }
  
  func delay(by: Int) {
    time += by
  }
}



extension Session {
  
  // Checks the current action queue.  Returns true if the action queue is empty after executing actions.
  func checkActions() -> Bool {
    
    if actionQueue.first != nil {
      while actionQueue.first!.time <= bot.globalTimer {
        let sessionAction = actionQueue.first!
        actionQueue.remove(at: 0)
        sessionAction.action(self)
        
        if actionQueue.count == 0 {
          return true
        }
      }
      return false
    }
    return true
  }
  
  // Im not sure about this, but whatever
  public func removeAction(name: String) {
    for (index, sessionAction) in actionQueue.enumerated() {
      if sessionAction.name == name {
        actionQueue.remove(at: index)
      }
    }
  }
  
  // Clears all actions (the bot process will clean it up next tick)
  public func clearActions() {
    actionQueue.removeAll()
  }
  
  // Ends the current session
  public func endSession(useAction: Bool = true) {
    if self.sessionEndAction != nil {
      self.sessionEndAction!(self)
    }
    
    bot.removeSession(session: self)
  }
}
