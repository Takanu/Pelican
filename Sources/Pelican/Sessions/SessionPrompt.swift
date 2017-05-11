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
  }
	
	/** 
	Creates a prompt thats connected to the Session, enabling it to automatically receive callback queries and react to player input,
	as well as to be sent in a chat.  A prompt is a specific model and controller system for defining a message attached to an inline
	message keyboard, including how it's sent and how it reacts to user input.
	- parameter inline: The inline keyboard to be used in this Prompt.
	- parameter text: Either the contents of the message to be sent as part of this prompt, or as a caption if a `FileLink` is also provided.
	- parameter upload: A specific file to be sent as the contents of the message belonging to this prompt.
	- parameter update: (Optional) The closure that is executed every time the prompt receives a callback query.
	*/
	public func createPrompt(name: String, inline: MarkupInline, text: String, file: FileLink?, update: ((Session, Prompt) -> ())? ) -> Prompt {
		let prompt = Prompt(name: name, inline: inline, text: text, file: file, update: update)
		prompt.controller = self
		self.add(prompt)
		return prompt
	}
	
	/** Attempts to retrieve a prompt with a given name. 
	*/
	public func get(withName name: String) -> Prompt? {
		for prompt in prompts {
			if prompt.name == name {
				return prompt
			}
		}
		
		return nil
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




/** 
Defines a single prompt that encapsulates an inline markup message and the behaviour behind it, including
how it reacts to user interaction, how it updates itself and how it stops processing user input.
 */
public class Prompt: ReceiveUpload {
  public var name: String = ""              // Optional name to use as a comparison between prompts.
  
  var text: String = ""
  var file: FileLink?
  var inline: MarkupInline
  var message: Message?
  var controller: PromptController?   // Links back to the controller for removal when complete, if required.
	var timer: Int = 0
	
	/// Returns the timer currently set to the prompt.  If 0, no timer has been set.
	public var getTimer: Int { return timer }
	/// Returns the body of text that defines the message the Prompt is attached to.
	public var getText: String { return text }
	/// Returns the optional file link that can be assigned to give the message media contents.
	public var getFile: FileLink? { return file }
	/// Returns the inline keyboard currently used for the Prompt.
	public var getInline: MarkupInline { return inline }
	/// Returns the Message that the Prompt has created and is responding to, if sent.
	public var getMessage: Message? { return message }
	
	
	/// What alert the user receives when they press an inline button and it worked.
  public var alertSuccess: String = ""
	/// What alert the user receives if it didn't work.
  public var alertFailure: String = ""
	/// What users are able to interact with the Prompt.  If the list is empty, anyone can interact with it.
  public var target: [User] = []
	/// How many times a button can be pressed by any user before the finish() is automatically called inside the Prompt.
  public var activationLimit: Int = 0
	/** Defines whether results are kept and stacked across interactions.  If true,
	the Prompt will block a player from making more than one interaction to the prompt until it is reset.*/
	public var recordInputs: Bool = false
	/** Removes the inline keyboard from the message if true, when the Prompt is finished.
	- warning: This will not work when a finish() closure has been defined due to Telegram Bot flood limits */
	public var removeInlineOnFinish: Bool = false
	
	
	/// Executed when an update is received by the prompt that was successful.
  public var update: ((Session, Prompt) -> ())?
	/// Executed when the Prompt has finished operating in it's current cycle.
  public var finish: ((Session, Prompt) -> ())?
  
  // Results and next steps
  var usersPressed: [User] = []             // Who ended up pressing a button.
  var results: [String:[User]] = [:]        // What each user pressed.
	public var lastResult: PromptResult?							// A result containing who pressed the last callback button.
  var completed: Bool = false               // Whether the prompt has met it's completion requirements.
	var finished: Bool = false								/// Whether this prompt is in a finished state.
	
	
	/// Returns a list of users that interacted with the prompt, ordered from who interacted with it first to last.
  public var getUsersPressed: [User] { return usersPressed }
	/// Defines whether or not the prompt is in a finished state.
	public var hasFinished: Bool { return finished }
  
	/** 
	For internal use only, Prompts have to be attached to the PromptController in order to function.
	*/
	init(name: String, inline: MarkupInline, text: String, file: FileLink?, update: ((Session, Prompt) -> ())? ) {
		self.name = name
    self.inline = inline
    self.text = text
    self.file = file
    self.update = update
  }
  
  /** Compares two prompts to figure out if they're the same.
   */
  public func compare(prompt: Prompt) -> Bool {
    
    if name != prompt.name {
      return false
    }
    
    if text != prompt.text {
      return false
    }
		
		if file != nil && prompt.file != nil {
			if file!.id != prompt.file!.id {
				return false
			}
		}
		
    if inline.keyboard.count != prompt.inline.keyboard.count {
      return false
    }
    
    var rowIndex = 0
    for row in inline.keyboard {
      let secondRow = prompt.inline.keyboard[rowIndex]
      
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
	
	/** Safely sets the timer, so long as the prompt does not have an instence of itself hanging around.
	*/
	public func setTimer(_ timer: Int) -> Bool {
		if message != nil { return false }
		
		self.timer = timer
		return true
	}
	
  
  /** 
	Sends the prompt to the given session as a message, ready to be interacted with.  
	If the prompt has been sent before without finishing, all results data will be reset and 
	the previously sent instance of this prompt will stop functioning (this behaviour will
	likely change in the future).
   */
  public func send(session: Session) {
		
		/// If it's being reused, reset the results.
		resetResults()
		
    for data in inline.getCallbackData()! {
      self.results[data] = []
    }
    
    // If we have an upload link, use that to send our prompt
    // Otherwise just send it normally
    if self.file != nil {
      session.send(link: self.file!, markup: inline, callback: self, caption: text)
			
			// If we have a timer, make it tick.
			if timer > 0 {
				session.delay(by: self.timer, stack: false, name: "prompt_\(name)_timer", action: self.finish)
			}
    }
    
    else {
      self.message = session.send(message: text, markup: inline)
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
			
			// Call the update closure and enclose the result
			let key = self.inline.getKey(withData: query.data!)
			self.lastResult = PromptResult(users: [query.from], key: key!)
			
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
			finish(session: session)
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
        
        // If the query matches a results type, add it to the results.
        if results[query]!.contains(where: {$0.tgID == user.tgID}) == false {
					
					// If we're supposed to be recording inputs, add it to the list.
					if recordInputs == true {
						results[query]!.append(user)
						usersPressed.append(user)
					}
					
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
	
	/** 
	Attempts to update both the inline keyboard and text of the currently displayed message.
	If no inline keyboard or text is defined, those components will be removed from the message.
	- parameter newInline: The new inline keyboard to be used under the message the Prompt belongs to.
	- parameter newText: The new text to be used for the message body (or caption if the message contains
	a file).  If nil, the text will be removed.
	- warning: If the inline keyboard is changed, all currently stored results will be lost.
	*/
	public func updateMessage(newInline: MarkupInline, newText: String, session: Session) {
		
		self.inline = newInline
		for data in inline.getCallbackData()! {
			self.results[data] = []
		}
		
		self.text = newText
		
		if self.file != nil {
			session.edit(caption: text, message: message!, markup: inline)
		}
			
		else {
			session.edit(withMessage: message!, text: text, markup: inline)
		}
	}
	/**
	Attempts to update the text of the currently displayed message.
	- parameter newText: The new text to be used for the message body (or caption if the message contains
	a file).  If empty, the text will be removed.
	*/
	public func updateText(newText: String, session: Session) {
		self.text = newText
		
		if self.file != nil {
			session.edit(caption: text, message: message!, markup: inline)
		}
			
		else {
			session.edit(withMessage: message!, text: text, markup: inline)
		}
	}
	
	/**
	Attempts to update the inline keyboard of the currently displayed message.
	- warning: If the inline keyboard is changed, all currently stored results will be lost.
	- parameter newInline: The new inline keyboard to be used under the message the Prompt belongs to.
	*/
	public func updateInline(newInline: MarkupInline, session: Session) {
		self.inline = newInline
		for data in inline.getCallbackData()! {
			self.results[data] = []
		}
		
		if self.file != nil {
			session.edit(caption: text, message: message!, markup: inline)
		}
			
		else {
			session.edit(withMessage: message!, text: text, markup: inline)
		}
	}
	
  /**
	Declares the prompt finished, removing it from the Prompt Controller and
	calling the finish() closure if it exists.  Results will remain until the prompt
	is sent again.
   */
  public func finish(session: Session) {
		
		// If it completed itself and the timer existed, ensure the action is removed to prevent a second trigger.
		if completed == true {
			if timer > 0 {
				session.removeAction(name: "prompt_\(name)_timer")
			}
		}
		
		// Removes the Prompt from the PromptController to prevent it from being processed.
		controller!.remove(self)
		
		// Perform any final clean-up operations without touching the results data
		finished = true
		
		
    // If we have a finish closure, run that to perform any final editing operations.
    if finish != nil {
      finish!(session, self)
    }
		
		// Otherwise if we want to remove the inline keyboard automatically when done, do it!
		else if removeInlineOnFinish == true {
			if self.file != nil {
				session.edit(caption: text, message: message!, markup: nil)
			}
				
			else {
				session.edit(withMessage: message!, text: text, markup: nil)
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
		finished = false
    results.removeAll()
		
    for data in inline.getCallbackData()! {
      self.results[data] = []
    }
  }
  
  /** A very cheap way to retain the message in a multi-threaded environment.  Will break in some way, guaranteed.
   */
  public func receiveMessage(message: Message) {
    self.message = message
		
		// If we have a timer, make it tick now the message is confirmed as sent.
		if timer > 0 {
			self.controller!.session!.delay(by: self.timer, stack: false, name: "prompt_\(name)_timer", action: self.finish)
		}
  }
}

/** Defines a single prompt result.  Can be used to define who last pressed a button 
as well as what button was the "winner".
*/
public struct PromptResult {
	public var users: [User] = []
	public var key: MarkupInlineKey
	
	init(users: [User], key: MarkupInlineKey) {
		self.users = users
		self.key = key
	}
}
