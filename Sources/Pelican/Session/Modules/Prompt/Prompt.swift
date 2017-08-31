//
//  ChatSessionPrompt.swift
//  Pelican
//
//  Created by Takanu Kyriako on 27/03/2017.
//
//

import Foundation
import Vapor
import FluentProvider

/** 
Defines a single prompt that encapsulates an inline markup message and the behaviour behind it, including
how it reacts to user interaction, how it updates itself and how it stops processing user input.
 */
public class Prompt: ReceiveUpload, Equatable {
	
	// CORE DATA
  public var name: String = ""              // Optional name to use as a comparison between prompts.
	var tag: SessionTag
  
  var text: String = ""
  var file: MessageFile?
  var inline: MarkupInline
	var event: ScheduleEvent?
  var message: Message?
  var controller: PromptController?   // Links back to the controller for removal when complete, if required.
	var timer: Duration = 0.seconds
	
	// CALLBACKS
	var addEvent: (ScheduleEvent) -> ()
	var removeEvent: (ScheduleEvent) -> ()
	var queuedEvents: [ScheduleEvent] = []
	
	
	// CORE DATA GETTERS
	/// Returns the timer currently set to the prompt.  If 0, no timer has been set.
	public var getTimer: Duration { return timer }
	/// Returns the body of text that defines the message the Prompt is attached to.
	public var getText: String { return text }
	/// Returns the optional file link that can be assigned to give the message media contents.
	public var getFile: MessageFile? { return file }
	/// Returns the inline keyboard currently used for the Prompt.
	public var getInline: MarkupInline { return inline }
	/// Returns the Message that the Prompt has created and is responding to, if sent.
	public var getMessage: Message? { return message }
	
	// SETTINGS
	/// What alert the user receives when they press an inline button and it worked.
  public var alertSuccess: String = ""
	/// What alert the user receives if it didn't work.
  public var alertFailure: String = ""
	/** What users are able to interact with the Prompt.  If the list is empty, anyone can interact with it.
	If all targets have interacted with the Prompt, finish() is automatically called.*/
  public var target: [User] = []
	/// How many times a button can be pressed by any user before the finish() is automatically called inside the Prompt.
  public var activationLimit: Int = 0
	/** Defines whether results are kept and stacked across interactions.  If true,
	the Prompt will block a player from making more than one interaction to the prompt until it is reset.*/
	public var recordInputs: Bool = false
	/** Removes the inline keyboard from the message if true, when the Prompt is finished.
	- warning: This will not work when a finish() closure has been defined due to Telegram Bot flood limits */
	public var removeInlineOnFinish: Bool = false
	/// If false, results will not be reset when the prompt is sent multiple times.
	public var resetResultsOnSend: Bool = true
	
	
	// ACTIONS
	/// Executed when an update is received by the prompt that was successful.
  public var update: ((Prompt) -> ())?
	/** Executed when the Prompt has finished operating in it's current cycle.  If you use this, you should at the end call
	`close(finalText:finalMarkup:)` when finished, in order to fully close the prompt */
  public var customClose: ((Prompt) -> ())?
	
	
  // RESULTS AND RESULT STATE
  var usersPressed: [User] = []             // Who ended up pressing a button.
  var results: [String:[User]] = [:]        // What each user pressed.
	public var lastResult: PromptResult?				// A result containing who pressed the last callback button.
	public var lastUpdate: Update?							// The last callback query to be received by the bot.
  var completed: Bool = false               // Whether the prompt has met it's completion requirements.
	var finished: Bool = false								/// Whether this prompt is in a finished state.
	
	// RESULT GETTERS
	/// Returns a list of users that interacted with the prompt, ordered from who interacted with it first to last.
  public var getUsersPressed: [User] { return usersPressed }
	/// Returns a list of users that didn't press any button
	public var getUsersIdle: [User] {
		return target.filter( { T in usersPressed.contains(where: { P in T.tgID == P.tgID} ) == false } )
	}
	/// Defines whether or not the prompt is in a finished state.
	public var hasFinished: Bool { return finished }
	
	
	
	/** 
	For internal use only, Prompts have to be attached to the PromptController in order to function.
	*/
	init(controller: PromptController, name: String, inline: MarkupInline, text: String, file: MessageFile?, update: ((Prompt) -> ())? ) {
		
		self.tag = controller.tag
		self.name = name
    self.inline = inline
    self.text = text
    self.file = file
    self.update = update
		
		self.addEvent = controller.addEvent
		self.removeEvent = controller.removeEvent
  }
	
	
	/** Safely sets the timer, so long as the prompt does not have an instence of itself hanging around.
	*/
	public func setTimer(_ timer: Duration) -> Bool {
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
  public func send() {
		
		/// If it's being reused, reset the results.
		if resetResultsOnSend == true {
			resetResults()
		}
		
		completed = false
		finished = false
		
    for data in inline.getCallbackData()! {
      self.results[data] = []
    }
    
    // If we have an upload link, use that to send our prompt
    // Otherwise just send it normally
    if self.file != nil {
			
			//let request = TelegramRequest.uploadFile(link: file!, callback: self, chatID: tag.getSessionID, markup: inline, caption: text, disableNtf: false, replyMessageID: 0)
			//_ = tag.sendRequest(request)
    }
    
    else {
      let request = TelegramRequest.sendMessage(chatID: tag.getSessionID, text: text, replyMarkup: inline)
			let response = tag.sendRequest(request)
			self.message = try! Message(row: Row(response.data!))
    }
		
		// If we have a timer, make it tick.
		if timer.rawValue > 0 {
			
			event = ScheduleEvent(delay: [timer]) {
				if self.customClose != nil {
					self.customClose!(self)
				}
			}
			
			addEvent(event!)
			queuedEvents.append(event!)
		}
  }
	
  
  
  /** 
	Receives a callback query to see if the prompt can use it as an input.
	- returns: Whether or not the callback query was successfully handled by the prompt.
   */
  func query(update: Update) -> Bool {
		
		let query = update.data as! CallbackQuery
		
    // Return early if some basic conditions are not met
    if query.data == nil { return false }
    if message == nil { return false }
    if query.message != nil {
      if query.message!.tgID != message!.tgID {
        return false
      }
    }
		
		// Assign the query to the "last query" slot.
		lastUpdate = update
    
    // Get the player mentioned in the query
    let user = query.from
    let data = query.data!
    
    // If we're here, the user has definitely interacted with this message.
    // Attempt to make the button request
    let success = pressButton(user, query: data)
    if success == true {
      if alertSuccess != "" {
				
				let request = TelegramRequest.answerCallbackQuery(queryID: query.id, text: alertSuccess, showAlert: true, url: nil)
				_ = tag.sendRequest(request)
      }
			
			// Call the update closure and enclose the result
			let key = self.inline.getKey(withData: query.data!)
			self.lastResult = PromptResult(users: [query.from], key: key!)
			
			if self.update != nil {
				self.update!(self)
			}
    }
      
		// Answer with an alert failure if you well... failed to contribute.
    else if success == false && alertFailure != "" {
			let request = TelegramRequest.answerCallbackQuery(queryID: query.id, text: alertFailure, showAlert: true, url: nil)
			_ = tag.sendRequest(request)
    }
    
    
    // If we reached the activation goal, call the action finish and remove the timer if one existed.
    if completed == true {
			
			if customClose != nil {
				customClose!(self)
			}
				
			else {
				if removeInlineOnFinish == true {
					close(finalText: text, finalMarkup: nil)
				}
				
				else {
					close(finalText: text, finalMarkup: inline)
				}
			}
    }
		
		return true
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
          
          if usersPressed.count >= activationLimit && activationLimit != 0 || activationLimit == 1 {
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
	Answers the last-received query with a custom response.
	*/
	public func answerLastQuery(text: String) {
		
		if lastUpdate == nil { return }
		
		let query = lastUpdate!.data as! CallbackQuery
		
		let request = TelegramRequest.answerCallbackQuery(queryID: query.id, text: text, showAlert: true, url: nil)
		_ = tag.sendRequest(request)
	}
	
	
	/** 
	Attempts to update both the inline keyboard and text of the currently displayed message.
	If no inline keyboard or text is defined, those components will be removed from the message.
	- parameter newInline: The new inline keyboard to be used under the message the Prompt belongs to.
	- parameter newText: The new text to be used for the message body (or caption if the message contains
	a file).  If nil, the text will be removed.
	- parameter resetResults: If true, all currently stored results will be lost.
	*/
	public func updateMessage(newInline: MarkupInline, newText: String, resetResults: Bool = false) {
		
		if resetResults == true {
			self.inline = newInline
			for data in inline.getCallbackData()! {
				self.results[data] = []
			}
		}
		
		self.text = newText
		
		if self.file != nil {
			_ = tag.sendRequest(TelegramRequest.editMessageCaption(chatID: message!.chat.tgID, messageID: message!.tgID, caption: text, replyMarkup: newInline))
		}
			
		else {
			_ = tag.sendRequest(TelegramRequest.editMessageText(chatID: message!.chat.tgID, messageID: message!.tgID, inlineMessageID: nil, text: text, replyMarkup: newInline))
		}
	}
	
	
	/**
	Attempts to update the text of the currently displayed message.
	- parameter newText: The new text to be used for the message body (or caption if the message contains
	a file).  If empty, the text will be removed.
	*/
	public func updateText(newText: String) {
		self.text = newText
		
		if self.file != nil {
			_ = tag.sendRequest(TelegramRequest.editMessageCaption(chatID: message!.chat.tgID, messageID: message!.tgID, caption: text, replyMarkup: inline))
		}
			
		else {
			_ = tag.sendRequest(TelegramRequest.editMessageText(chatID: message!.chat.tgID, messageID: message!.tgID, inlineMessageID: nil, text: text, replyMarkup: inline))
		}
	}
	
	/**
	Attempts to update the inline keyboard of the currently displayed message.
	- parameter newInline: The new inline keyboard to be used under the message the Prompt belongs to.
	- parameter resetResults: If true, all currently stored results will be lost.
	*/
	public func updateInline(newInline: MarkupInline, resetResults: Bool = false) {
		if resetResults == true {
			self.inline = newInline
			for data in inline.getCallbackData()! {
				self.results[data] = []
			}
		}
		
		if self.file != nil {
			_ = tag.sendRequest(TelegramRequest.editMessageCaption(chatID: message!.chat.tgID, messageID: message!.tgID, caption: text, replyMarkup: inline))
		}
			
		else {
			_ = tag.sendRequest(TelegramRequest.editMessageReplyMarkup(chatID: message!.chat.tgID, messageID: message!.tgID, replyMarkup: inline))
		}
	}
	
  /**
	Declares the prompt finished, removing it from the Prompt Controller and
	calling the finish() closure if it exists.  Results will remain until the prompt
	is sent again.
   */
	public func close(finalText: String, finalMarkup: MarkupInline?) {
		
		// If it completed itself and the timer existed, ensure the action is removed to prevent a second trigger.
		if completed == true {
			queuedEvents.forEach( { self.removeEvent($0) } )
		}
		
		// Removes the Prompt from the PromptController to prevent it from being processed.
		controller!.remove(self)
		
		// Perform any final clean-up operations without touching the results data
		finished = true
		
		// Otherwise if we want to remove the inline keyboard automatically when done, do it!
		if finalText == text {
			if finalMarkup != nil {
				if finalMarkup! == inline {
					return
				}
			}
		}
		
		if self.file != nil {
			_ = tag.sendRequest(TelegramRequest.editMessageCaption(chatID: message!.chat.tgID, messageID: message!.tgID, caption: finalText, replyMarkup: finalMarkup))
		}
				
		else {
			_ = tag.sendRequest(TelegramRequest.editMessageText(chatID: message!.chat.tgID, messageID: message!.tgID, inlineMessageID: nil, text: finalText, replyMarkup: finalMarkup))
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
      returnResults.append((name!, data, users))
    }
    
    return returnResults
    
    // Need randomiser code that's MIT
    //return winner.getRandom
  }
  
  /** Cleans the system for later use.
   */
  private func resetResults() {
    usersPressed = []
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
	
	/** Compares two prompts to figure out if they're the same.
	*/
	static public func ==(lhs: Prompt, rhs: Prompt) -> Bool {
		
		if lhs.name != rhs.name {
			return false
		}
		
		if lhs.text != lhs.text {
			return false
		}
		
		if lhs.file != nil && rhs.file != nil {
			if lhs.file!.url != rhs.file!.url {
				return false
			}
		}
		
		if lhs.inline.keyboard.count != rhs.inline.keyboard.count {
			return false
		}
		
		var rowIndex = 0
		for row in lhs.inline.keyboard {
			let secondRow = rhs.inline.keyboard[rowIndex]
			
			var buttonIndex = 0
			for button in row {
				let secondButton = secondRow[buttonIndex]
				if button == secondButton {
					return false
				}
				buttonIndex += 1
			}
			rowIndex += 1
		}
		
		return true
	}
}


