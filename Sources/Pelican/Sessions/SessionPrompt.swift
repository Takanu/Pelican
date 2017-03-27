//
//  SessionPrompt.swift
//  Pelican
//
//  Created by Takanu Kyriako on 27/03/2017.
//
//

import Foundation
import Vapor

/** Defines a convenient way to create inline options for users and to provide quick ways of managing and 
 customising their behaviours.
 */
public class PromptController {
  var prompts: [Prompt] = []
  public var count: Int { return prompts.count }
  
  public func add(_ prompt: Prompt) {
    // Check to make sure it doesn't already exist, if it does pull it
    for (index, ownedPrompt) in prompts.enumerated() {
      if ownedPrompt.compare(prompt: prompt) == true {
        prompts.remove(at: index)
      }
    }
    
    // Add the prompt to the stack
    prompts.append(prompt)
    prompt.controller = self
  }
  
  /** A shortcut for creating and adding a prompt to the controller.
   */
  public func createPrompt(inline: MarkupInline, message: String, type: PromptMode) {
    let prompt = Prompt(inline: inline, message: message)
    prompt.setConfig(type)
    add(prompt)
  }
  
  
  /** Finds a prompt that matches the given query.
  */
  public func search(withQuery query: CallbackQuery) -> Prompt? {
    for prompt in prompts {
      if prompt.message != nil {
        if prompt.message!.tgID == query.message?.tgID {
          return prompt
        }
      }
    }
    
    return nil
  }
  
  /** Filters a query for a prompt to receive and handle.
   */
  func filterQuery(_ query: CallbackQuery, session: Session) {
    for prompt in prompts {
      if prompt.message != nil {
        if prompt.message!.tgID == query.message?.tgID {
          prompt.query(query: query, session: session)
        }
      }
    }
  }
  
  /** Finds a prompt that matches the given query.
   */
  public func remove(_ prompt: Prompt) {
    // Check to make sure it doesn't already exist, if it does pull it
    for (index, ownedPrompt) in prompts.enumerated() {
      if ownedPrompt.compare(prompt: prompt) == true {
        prompts.remove(at: index)
        return
      }
    }
  }
}




/** Defines a single prompt that encapsulates an inline markup messages and the behaviour of it.
 */
public class Prompt {
  var timer: Int = 0
  var messageText: String = ""
  var inline: MarkupInline
  var message: Message?
  var controller: PromptController?   // Link back to the controller for removal when done.
  
  public var alert: String = ""             // What alert the user receives when they press an inline button.
  public var target: [User] = []            // What users are able to interact with the prompt.  If none, any can interact with it.
  public var forceNext: Bool = true         // Whether the next closure is used if we finished without the responses being completed.
  public var activationLimit: Int = 1       // How many times a button can be pressed by any user before the prompt is completed.
  public var removeOnCompletion: Bool = true  // When the prompt finishes, should the inline buttons and itself be removed?
  
  public var next: ((Session, Prompt) -> ())?       // What closure is run once the prompt finishes.
  public var update: ((Session, Prompt) -> ())?     // What closure is run if the prompt receives a new update
  
  // Results and next steps
  var usersPressed: [User] = []             // Who ended up pressing a button
  var results: [String:[User]] = [:]        // What each user pressed
  var completed: Bool = false               // Whether the prompt has met it's completion requirements.
  
  
  init(inline: MarkupInline, message: String) {
    self.inline = inline
    self.messageText = message
  }
  
  public func compare(prompt: Prompt) -> Bool {
    if messageText != prompt.messageText {
      return false
    }
    if inline.keyboard.count != prompt.inline.keyboard.count {
      return false
    }
    
    var rowIndex = 0
    for row in inline.keyboard {
      var secondRow = prompt.inline.keyboard[rowIndex]
      
      var buttonIndex = 0
      for button in row.keys {
        let secondButton = secondRow.keys[buttonIndex]
        if button.compare(key: secondButton) == false {
          return false
        }
        buttonIndex += 1
      }
      rowIndex += 1
    }
    
    return true
  }
  
  
  /** Unsure how this will integrate, currently acts as a placeholder to group common usage patterns.
   */
  public func setConfig(_ type: PromptMode) {
    switch type {
    case .ephemeral:
      self.timer = 0
      self.removeOnCompletion = true
      self.activationLimit = 1
      
    case .persistent:
      self.timer = 0
      self.removeOnCompletion = false
      self.activationLimit = 1
      
    case .active:
      self.timer = 0
      self.removeOnCompletion = false
      self.activationLimit = 0
      
    }
  }
  
  /** Sends the prompt to the given session.
   */
  public func send(session: Session) {
    func setupChoice(_ session: Session) {
      for data in inline.getCallbackData()! {
        self.results[data] = []
      }
      
      self.message = session.send(message: messageText, markup: inline)
      session.callbackQueryState = self.query
      
      // If we have a timer, make it tick.
      if timer > 0 {
        session.delay(by: self.timer, stack: false, name: "prompt_choice", action: self.finish)
      }
    }
    
    if timer > 0 {
      session.delay(by: timer, stack: true, action: setupChoice)
    }
    
    else {
      setupChoice(session)
    }
  }
  
  
  /** Receives a callback query to see if the prompt can use it as an input.
   */
  func query(query: CallbackQuery, session: Session) {
    
    // Return early if some basic conditions are not met
    if query.data == nil { return }
    if message == nil { return }
    if query.message != nil {
      if query.message!.tgID != message!.tgID {
        return
      }
    }
    
    // Get the player mentioned in the query
    let user = query.from
    let data = query.data!
    
    // If we're here, the user has definitely interacted with this message.
    // Attempt to make the button request
    let success = pressButton(user, query: data)
    if success == true && alert != "" {
      session.answer(query: query, text: alert)
      
      if update != nil {
        update!(session, self)
      }
    }
    
    
    // If we reached the activation goal, call the action finish and remove the timer if one existed.
    if completed == true {
      finish(session)
    }
  }
  
  
  /* Attempts to register a player to a choice.  Returns whether it was successful. 
   */
  private func pressButton(_ user: User, query: String) -> Bool {
    
    if completed == true { return false }
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
            completed = true
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
    if removeOnCompletion == true {
      session.edit(message: message!, markup: nil)
      
      if controller != nil {
        controller!.remove(self)
      }
    }
    
    
    if completed == false {
      
      // If we didn't get a finish state but someone pressed the button, we still need to enter the next phase
      // or clean up and return.
      if usersPressed.count != 0 {
        session.resetTimerAssists()
        
        if forceNext == true && next != nil {
          next!(session, self)
        }
        
        reset()
        return
      }
        
      else { return }
    }
      
    else {
      session.resetTimerAssists()
      
      if next != nil {
        next!(session, self)
      }
      
      reset()
      return
    }
  }
  
  /** Cleans the system for later use.
   */
  private func reset() {
    timer = 0
    messageText = ""
    message = nil
    alert = ""
    forceNext = true
    removeOnCompletion = true
    target = []
    
    usersPressed = []
    results = [:]
    completed = false
    next = nil
  }
}


/** Shortcuts for configuring a prompt for specific purposes.
 */
public enum PromptMode: String {
  case ephemeral    // One time activation, destroyed on completion
  case persistent   // One time activations, persistent
  case active       // One time activations, persistent and can update itself
}
