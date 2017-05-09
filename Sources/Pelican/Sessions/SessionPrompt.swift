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
  var session: Session?
  public var enabled: Bool = true
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
    prompt.send(session: session!)
  }
  
  /** A shortcut for creating and adding a prompt to the controller.  Covers all commonly used types of prompts.
   */
  //  public func createPrompt(inline: MarkupInline, message: String, type: PromptMode, next: @escaping (Session, Prompt) -> ()) -> Prompt {
  //    let prompt = Prompt(inline: inline, message: message, next: next)
  //    prompt.setConfig(type)
  //    add(prompt)
  //
  //    return prompt
  //  }
  
  public func createEphemeralPrompt(inline: MarkupInline, text: String, upload: FileLink? = nil, finish: ((Session, Prompt) -> ())? = nil, next: @escaping (Session, Prompt) -> ()) -> Prompt {
    let prompt = Prompt(asEphemeral: inline, text: text, upload: upload, finish: finish, next: next)
    add(prompt)
    
    return prompt
  }
  
  public func createPersistentPrompt(inline: MarkupInline, text: String, upload: FileLink? = nil, promptName: String, next: @escaping (Session, Prompt) -> ()) -> Prompt {
    let prompt = Prompt(asPersistent: inline, text: text, upload: upload, promptName: promptName, next: next)
    add(prompt)
    
    return prompt
  }
  
  public func createVotePrompt(inline: MarkupInline, text: String, upload: FileLink? = nil, promptName: String, time: Int = 0, update: ((Session, Prompt) -> ())? = nil, next: @escaping (Session, Prompt) -> ()) -> Prompt {
    let prompt = Prompt(asVote: inline, text: text, upload: upload, promptName: promptName, time: time, update: update, next: next)
    add(prompt)
    
    return prompt
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
    if enabled == false { return }
    
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
  
  /** Removes all prompts from the system.
   */
  public func removeAll() {
    prompts.removeAll()
  }
}




/** Defines a single prompt that encapsulates an inline markup message and the behaviour behind it.
 */
public class Prompt: ReceiveUpload {
  var timer: Int = 0
  public var name: String = ""              // Optional name to use as a comparison between prompts.
  
  var text: String = ""
  var upload: FileLink?
  
  public var getText: String { return text }
  var inline: MarkupInline
  var message: Message?
  var controller: PromptController?   // Links back to the controller for removal when complete, if required.
  
  var mode: PromptMode = .undefined
  public var alertSuccess: String = ""       // What alert the user receives when they press an inline button and it worked.
  public var alertFailure: String = ""       // What alert the user receives if it didn't.
  public var target: [User] = []            // What users are able to interact with the prompt.  If none, any can interact with it.
  public var forceNext: Bool = true         // Whether the next closure is used if we finished without receiving any results.
  public var activationLimit: Int = 1       // How many times a button can be pressed by any user before the prompt is completed.
  public var removeOnCompletion: Bool = true  // When the prompt finishes, should the inline buttons and itself be removed?
  
  var next: ((Session, Prompt) -> ())?       // What closure is run once the prompt finishes.
  var update: ((Session, Prompt) -> ())?     // What closure is run if the prompt receives a new update
  var finish: ((Session, Prompt) -> ())?     // What closure is run to determine the final contents of the message.  Overrides removeOnCompletion.
  
  // Results and next steps
  var usersPressed: [User] = []             // Who ended up pressing a button.
  var results: [String:[User]] = [:]        // What each user pressed.
  var completed: Bool = false               // Whether the prompt has met it's completion requirements.
  
  public var getUsersPressed: [User] { return usersPressed }
  
  
  public init(inline: MarkupInline, text: String, upload: FileLink? = nil, next: @escaping (Session, Prompt) -> ()) {
    self.inline = inline
    self.text = text
    self.upload = upload
    self.next = next
  }
  
  public init(asEphemeral inline: MarkupInline, text: String, upload: FileLink? = nil, finish: ((Session, Prompt) -> ())? = nil, next: @escaping (Session, Prompt) -> ()) {
    self.inline = inline
    self.text = text
    self.upload = upload
    self.finish = finish
    self.next = next
    
    self.setConfig(.ephemeral)
  }
  
  public init(asPersistent inline: MarkupInline, text: String, upload: FileLink? = nil, promptName: String, next: @escaping (Session, Prompt) -> ()) {
    self.inline = inline
    self.text = text
    self.upload = upload
    self.next = next
    self.name = promptName
    
    self.setConfig(.persistent)
  }
  
  public init(asVote inline: MarkupInline, text: String, upload: FileLink? = nil, promptName: String, time: Int = 0, update: ((Session, Prompt) -> ())? = nil, next: @escaping (Session, Prompt) -> ()) {
    self.timer = time
    self.inline = inline
    self.text = text
    self.upload = upload
    self.update = update
    self.next = next
    self.name = promptName
    
    self.setConfig(.vote)
  }
  
  /** Compares two prompts to figure out if they're the same.
   */
  public func compare(prompt: Prompt) -> Bool {
    
    if name != prompt.name {
      return false
    }
    if mode.rawValue != prompt.mode.rawValue {
      return false
    }
    
    // At this point, if it's an active-type prompt, then this will be enough to return true.
    if mode == .persistent { return true }
    
    
    if text != prompt.text {
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
   Disabled until i find something else for it
   */
  func setConfig(_ type: PromptMode) {
    switch type {
    case .ephemeral:
      self.timer = 0
      self.removeOnCompletion = true
      self.activationLimit = 1
      self.mode = .ephemeral
      
    case .persistent:
      self.timer = 0
      self.removeOnCompletion = false
      self.activationLimit = 1
      self.mode = .persistent
      
    case .vote:
      self.removeOnCompletion = true
      self.activationLimit = 0
      self.mode = .vote
      
    default:
      return
    }
  }
  
  /** Sends the prompt to the given session, and adds itself to the controller if not already there.
   */
  public func send(session: Session) {
    for data in inline.getCallbackData()! {
      self.results[data] = []
    }
    
    // Add the prompt to the controller, just in case it's being reused and has already ended.
    controller!.add(self)
    
    // If we have an upload link, use that to send our prompt
    // Otherwise just send it normally
    if self.upload != nil {
      session.send(link: self.upload!, markup: inline, callback: self, caption: text)
    }
    
    else {
      self.message = session.send(message: text, markup: inline)
    }
    
    
    // If we have a timer, make it tick.
    if timer > 0 {
      session.delay(by: self.timer, stack: false, name: "prompt_choice", action: self.finish)
    }
  }
  
  /** Attempts to update the message this prompt is associated with
   */
  public func update(newInline: MarkupInline? = nil, newText: String? = nil, session: Session) {
    if newInline == nil && newText == nil { return }
    if newInline != nil {
      self.inline = newInline!
      for data in inline.getCallbackData()! {
        self.results[data] = []
      }
    }
    
    if newText != nil {
      self.text = newText!
    }
    
    if self.upload != nil {
      session.edit(caption: text, message: message!, markup: inline)
    }
    
    else {
      session.edit(withMessage: message!, text: text, markup: inline)
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
    if success == true {
      if alertSuccess != "" {
        session.answer(query: query, text: alertSuccess)
      }
      
      if update != nil {
        update!(session, self)
      }
    }
      
      // Answer with an alert failure if you well... failed to contribute.
    else if success == false && alertFailure != "" {
      session.answer(query: query, text: alertFailure)
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
    if target.contains(where: {$0.tgID == user.tgID}) == true || target.count == 0 {
      
      // If they've already pressed it, they can't press it again.
      if usersPressed.contains(where: {$0.tgID == user.tgID } ) == false {
        
        // If the query doesn't match a results type, don't accept it.
        if results[query]!.contains(where: {$0.tgID == user.tgID}) == false {
          results[query]!.append(user)
          usersPressed.append(user)
          
          print("Prompt Choice Pressed  - \(user.firstName)")
          
          if usersPressed.count >= activationLimit && activationLimit != 0 {
            completed = true
          }
            
            // Otherwise if everyone that can vote has, also consider things done
          else if usersPressed.count >= target.count && target.count != 0 {
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
    if timer != 0 {
      session.removeAction(name: "prompt_choice")
    }
    
    // If we have a finish closure, run that and see if we need to
    // remove the prompt from the controller.
    if finish != nil {
      finish!(session, self)
      if removeOnCompletion == true {
        if controller != nil {
          controller!.remove(self)
        }
      }
    }
    
    // If not but we should remove it anyway, perform that action.
    if removeOnCompletion == true {
      session.edit(withMessage: message!, markup: nil)
      
      if controller != nil {
        controller!.remove(self)
      }
    }
    
    // If the requirements weren't completed, see if we have to next()
    if completed == false {
      
      if forceNext == true && next != nil {
        session.resetTimerAssists()
        next!(session, self)
        resetResults()
      }
      else { return }
    }
    
    // If we don't move to next(), just reset the results.
    else {
      session.resetTimerAssists()
      
      if next != nil {
        next!(session, self)
      }
      
      resetResults()
      return
    }
  }
  
  /** Kills the prompt manually, removing it's inline buttons and pulling it from the controller.  Next will not be triggered.
   */
  public func end(withText text: String? = nil, session: Session, removeMarkup: Bool = true) {
    // Just in case the action is in the timer system, remove it
    if timer != 0 {
      session.removeAction(name: "prompt_choice")
    }
    
    // If we have a finish closure, run that and see if we need to
    // remove the prompt from the controller.
    if removeMarkup == true {
      if self.upload != nil {
        if text == nil || text == "" {
          session.edit(caption: "", message: message!, markup: nil)
        }
        
        else {
          session.edit(caption: text!, message: message!, markup: nil)
        }
      }
        
      else {
        session.edit(withMessage: message!, text: text, markup: nil)
      }
      if controller != nil {
        controller!.remove(self)
      }
    }
  }
  
  
  /** Returns a single, successful regardless of whether there was a tie, by random selelcting from the tied options.
   Includes results for the users that selected it.
   */
  public func getWinner() -> (name: String, data: String, users: [User], key: MarkupInlineKey)? {
    var winners: [String] = []
    var users: [[User]] = []
    var winVotes = 0
    
    for (index, item) in results.enumerated() {
      if index == 0 {
        winners.append(item.key)
        users.append(item.value)
        winVotes = item.value.count
      }
      else if item.value.count == winVotes {
        winners.append(item.key)
        users.append(item.value)
      }
      else if item.value.count > winVotes {
        winners.removeAll()
        users.removeAll()
        winners.append(item.key)
        users.append(item.value)
        winVotes = item.value.count
      }
    }
    
    if winVotes == 0 { return nil }
    return (inline.getLabel(withData: winners[0])!, winners[0], users[0], inline.getKey(withData: winners[0])!)
    
    // Need randomiser code that's MIT
    //return winner.getRandom
  }
  
  public func getResults(ordered: Bool) -> [(name: String, data: String, users: [User])] {
    var returnResults: [(name: String, data: String, users: [User])] = []
    
    for result in results {
      let data = result.key
      let name = inline.getLabel(withData: result.key)
      let users = result.value
      returnResults.append((data, name!, users))
    }
    
    return returnResults
    
    // Need randomiser code that's MIT
    //return winner.getRandom
  }
  
  /** Cleans the system for later use.
   */
  private func resetResults() {
    usersPressed = []
    completed = false
    
    results.removeAll()
    for data in inline.getCallbackData()! {
      self.results[data] = []
    }
  }
  
  /** A very cheap way to retain the message in a multi-threaded environment.  Will break in some way, guaranteed.
   */
  public func receiveMessage(message: Message) {
    self.message = message
  }
}


/** Shortcuts for configuring a prompt for specific purposes.
 */
public enum PromptMode: String {
  case ephemeral    // One time activation, destroyed on completion
  case persistent   // One time activations, persistent
  case vote         // Multiple activations, VOTE!
  case undefined    // Default
}
