//
//  ChatSessionActions.swift
//  Pelican
//
//  Created by Takanu Kyriako on 27/03/2017.
//
//

import Foundation
import Vapor

/** 
Defines a class that handles the creation, coordination and execution of delayed Telegram API calls inside a chat session.
Useful when preparing sequences of messages to be sent out in order to present language and information in a steadier
and more natural manner.  

This is designed as a simple content scheduler and not a full dispatch/job system currently.  For that look to other
frameworks such as Jobs - https://github.com/BrettRToomey/Jobs.
*/
public class ChatSessionQueue {
	/// The list of actions currently queued for dispatch.
	var queue: [QueueAction] = []
	/// The session this queue belongs to.
	var session: ChatSession?
	/** The current time "playback" point for the action queue.  When the queue is reset this resets to 0, and will only start being counted
	once an action is available. */
	var time: Int = 0
	
	/** 
	Adds an action to the session queue, that allows an enclosure to be executed at a later time, with the included session.
	- parameter byDelay: The time this action has to wait from when the last action was executed.  If queued after an action that has a defined
	`viewTime` thats longer than they delay, that will be used as the time that this action can be sent as one in the stack before it.
	- parameter viewTime: The length of the pause after this action is executed before another action in the queue can be executed.
	If the action next in the stack has a delay timer thats longer, that will be used instead as the pause between the two actions.
	- parameter name: A name for the action, that can be used to search for and edit the action later on.
	- parameter action: The closure to be executed when the queue executes this action.
	*/
	public func add(byDelay delay: Int, viewTime: Int, name: String = "", action: @escaping (ChatSession) -> ()) {
		
		// Calculate what kind of delay we're using
		var execTime = 0
		if queue.count > 0 {
			let lastAction = self.queue.last!
			
			// If the delay is longer than the view time, use that.  Otherwise use the delay
			if lastAction.viewTime > delay {
				execTime = lastAction.time + lastAction.viewTime
			}
			
			else if lastAction.viewTime <= delay {
				execTime = lastAction.time + delay
			}
		}
		
		else {
			execTime = delay
		}
		
		// Add it directly to the end of the stack
		let action = QueueAction(session: session!, execTime: execTime, viewTime: viewTime, action: action, name: name)
		queue.append(action)
		session!.bot.addChatSessionEvent(session: session!)
		
		//print("New Delay - \(execTime)")
	}
	
	/** 
	A shorthand function for sending a single message in a delayed fashion, through the action system.
	This makes assumptions that you're sending a message with specific default parameters (no replies, 
	no parse mode, no web preview, no notification disabling).
	- parameter delay: The time this action has to wait from when the last action was executed.  If queued after an action that has a defined
	`viewTime` thats longer than they delay, that will be used as the time that this action can be sent as one in the stack before it.
	- parameter viewTime: The length of the pause after this action is executed before another action in the queue can be executed.
	If the action next in the stack has a delay timer thats longer, that will be used instead as the pause between the two actions.
	- parameter message: The text message you wish to send.
	- parameter markup: If any special message functions should be applied.
	*/
	public func addMessage(delay: Int, viewTime: Int, message: String, markup: MarkupType? = nil) {
		self.add(byDelay: delay, viewTime: viewTime) { session in
			_ = session.sendMessage(message, markup: markup, reply: false, webPreview: false, disableNtf: false)
		}
	}
	
	/**
	A function for sending a single message in a delayed fashion, through the action system.  Allows configuration of all parameters.
	- parameter delay: The time this action has to wait from when the last action was executed.  If queued after an action that has a defined
	`viewTime` thats longer than they delay, that will be used as the time that this action can be sent as one in the stack before it.
	- parameter viewTime: The length of the pause after this action is executed before another action in the queue can be executed.
	If the action next in the stack has a delay timer thats longer, that will be used instead as the pause between the two actions.
	- parameter message: The text message you wish to send.
	- parameter markup: If any special message functions should be applied.
	*/
	public func addMessageEx(delay: Int, viewTime: Int, message: String, markup: MarkupType? = nil, reply: Bool = false, parseMode: MessageParseMode = .none, webPreview: Bool = false, disableNtf: Bool = false) {
		self.add(byDelay: delay, viewTime: viewTime) { session in
			_ = session.sendMessage(message, markup: markup, reply: reply, parseMode: parseMode, webPreview: webPreview, disableNtf: disableNtf)
		}
	}
	
	
	/// Properly calculates a wait time to send a message based on a pause and the previous dialog length.
	public func addDialog(delay: Int, dialog: String, markup: MarkupType? = nil) {
		let viewTime = calculateReadTime(text: dialog)
		
		self.add(byDelay: delay, viewTime: viewTime) { session in
			_ = session.sendMessage(dialog, markup: markup, reply: false, webPreview: false, disableNtf: false)
		}
	}
	
	/*
	// Edits the text contents of a message in a delayed fashion.  A last sent message must be available.
	public func addEdit(delay: Int, message: String, markup: MarkupType? = nil, reply: Bool = false, parseMode: String = "", webPreview: Bool = false, disableNtf: Bool = false) {
		
	}
	
	// Edits the text contents of a message in a delayed fashion.  A last sent message must be available.
	public func addEditEx(viewTime: Int, message: String, markup: MarkupType? = nil, reply: Bool = false, parseMode: String = "", webPreview: Bool = false, disableNtf: Bool = false) {
		
	}
	*/
	
	/** Calculates a read time for dialog-specific queue functions */
	func calculateReadTime(text: String) -> Int {
		let wordsPerMinute = 250
		
		let wordCount = text.components(separatedBy: NSCharacterSet.whitespaces).count
		let readTime = Int(ceil(Float(wordCount) / Float(wordsPerMinute / 60)))
		return Int(readTime)
	}
	
	/** Increments the timer and checks if any actions need executing.  Returns true if no actions are left */
	func incrementTimer() -> Bool {
		//print("Checking for actions...")
		//print(queue.map({$0.time}))
		
		time += 1
		
		if queue.first != nil {
			while queue.first!.time <= time {
				
				let action = queue.first!
				queue.removeFirst()
				
				// If the queue is empty, reset the timer
				if queue.count == 0 {
					time = 0
				}
				
				//print("Executing Action - \(action.time)")
				action.action(session!)
				
				// Also return true if empty
				if queue.count == 0 {
					return true
				}
				
				
			}
			return false
		}
		
		else {
			time = 0
			return true
		}
	}
	
	/** 
	Attempts to find an action that matches the name provided to remove it from the queue.
	Does not affect already calculated times (currently). 
	*/
	public func remove(name: String) -> Bool {
		for (index, action) in queue.enumerated() {
			if action.name == name {
				queue.remove(at: index)
				return true
			}
		}
		
		return false
	}
	
	/** Clears all actions in the queue. */
	public func clear() {
		queue.removeAll()
		time = 0
	}
}

// Defines a queued action for a specific session, to be run at a later date
class QueueAction {
  var name: String = ""				// Only used if the user may later want to find and remove the action before being played.
  var session: ChatSession				// The session to be affected
	var viewTime: Int = 0				// (Optional)
  var time: Int								// The time at which this should be executed.
  var action: (ChatSession) -> ()	// The closure to be executed.
  
	init(session: ChatSession, execTime: Int, viewTime: Int, action: @escaping (ChatSession) -> (), name: String = "") {
    self.name = name
    self.session = session
    self.time = execTime
		self.viewTime = viewTime
    self.action = action
  }
  
  func execute() {
    action(session)
  }
	
	/*
  func changeTime(_ globalTime: Int) {
    time = globalTime
  }
	*/
  
  func delay(by: Int) {
    time += by
  }
}

