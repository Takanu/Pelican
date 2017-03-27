//
//  SessionPrompt.swift
//  Pelican
//
//  Created by Takanu Kyriako on 27/03/2017.
//
//

import Foundation
import Vapor

/** Defines a convenient way to create options for users and to provide convenient ways of managing and handling them.
 */
public class Prompt {
  
  var time: Int = 0
  var message: Message?
  var inline: MarkupInline?
  var session: Session?
  
  public var alert: String = ""
  public var autoRemoveInline: Bool = true
  public var target: [User] = []
  public var next: ((Session) -> ())?
  public var forceNext: Bool = true
  
  // Results and next steps
  var usersPressed: [User] = []
  var results: [String:[User]] = [:]
  var finished: Bool = false
  
  
  init() {}
  
  
  public func start(inline: MarkupInline, message: String, timer: Int = 0) {
    func setupChoice(_ session: Session) {
      session.callbackQueryState = nil
      self.inline = inline
      self.time = timer
      
      for data in inline.getCallbackData()! {
        self.results[data] = []
      }
      
      self.message = session.send(message: message, markup: inline)
      session.callbackQueryState = self.query
      
      // If we have a timer, make it tick.
      if timer > 0 {
        session.delay(by: self.time, stack: false, name: "prompt_choice", action: self.finish)
      }
    }
    
    if timer > 0 {
      session!.delay(by: timer, stack: true, action: setupChoice)
    }
    
    else {
      setupChoice(session!)
    }
  }
  
  
  // Is the callback query state for when someone presses the button.
  private func query(query: CallbackQuery, session: Session) {
    if query.data == nil { return }
    
    // Get the player mentioned in the query
    let user = query.from
    let data = query.data!
    
    // Attempt to make the button request
    let success = pressButton(user, query: data)
    if success == true && alert != "" { session.answer(query: query, text: alert) }
    
    
    // If we reached the activation goal, call the action finish and remove the timer if one existed.
    if finished == true {
      finish(session)
    }
  }
  
  
  /* Attempts to register a player to a choice.  Returns whether it was successful. */
  private func pressButton(_ user: User, query: String) -> Bool {
    
    if finished == true { return false }
    if results[query] == nil { return false }
    
    // If the player isnt in the context, they can't press it
    if target.contains(where: {$0.tgID == user.tgID}) == true {
      
      // If they've already pressed it, they can't press it again.
      if usersPressed.contains(where: {$0.tgID == user.tgID } ) == true {
        
        // If the query doesn't match a results type, don't accept it.
        if results[query]!.contains(where: {$0.tgID == user.tgID}) == false {
          results[query]!.append(user)
          usersPressed.append(user)
          
          print("Prompt Choice Pressed  - \(user.firstName)")
            
          // Otherwise if everyone that can vote has, also consider things done
          if usersPressed.count >= target.count {
            finished = true
          }
          
          return true
        }
      }
    }
    return false
  }
  
  /** Completes the prompt activity.
   */
  public func finish(_ session: Session) {
    // Just in case the action is in the timer system, remove it
    session.removeAction(name: "prompt_choice")
    session.callbackQueryState = nil
    
    // Remove the inline keyboard from the message if we have one.
    if inline != nil && autoRemoveInline == true {
      session.edit(message: message!, markup: nil)
    }
    
    if finished == false {
      
      // If we didn't get a finish state but someone pressed the button, we still need to enter the next phase
      // or clean up and return.
      if usersPressed.count != 0 {
        session.resetTimerAssists()
        
        if forceNext == true && next != nil {
          next!(session)
        }
        
        reset()
        return
      }
        
      else { return }
    }
      
    else {
      session.resetTimerAssists()
      
      if forceNext == true && next != nil {
        next!(session)
      }
      
      reset()
      return
    }
  }
  
  /** Cleans the system for later use.
   */
  private func reset() {
    time = 0
    message = nil
    inline = nil
    alert = ""
    forceNext = true
    autoRemoveInline = true
    target = []
    
    usersPressed = []
    results = [:]
    finished = false
    next = nil
  }
  
}
