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
Defines a class that acts as a proxy for the Pelican-managed Schedule class, thats used to delay the execution of functions.
This class includes many helper and convenience functions to make
*/
public class ChatSessionQueue {
	
	/// DATA
	/// The chat ID of the session this queue belongs to.
	var chatID: Int
	/// A callback to the Pelican `sendRequest` method, enabling the class to send it's own requests.
	var tag: SessionTag
	
	// CALLBACKS
	/// A callback to Schedule, to add an event to the queue
	var addEvent: (ScheduleEvent) -> ()
	var removeEvent: (ScheduleEvent) -> ()
	
	
	/** 
	Copies of the ScheduleEvents that are generated to submit to the schedule, in case this class needs to remove
	any events already in the schedule.
	*/
	var eventHistory: [ScheduleEvent] = []
	
	/// The point at which the last addition to the queue is set to play, relative to the current time value.
	var lastEventTime: Double = 0
	
	/// The last event "view time" request, used to calculate when the next event should be queued at.
	var lastEventViewTime: Double = 0
	

	
	/**
	Initialises the Queue class with a Pelican-derived Schedule.
	*/
	init(chatID: Int, schedule: Schedule, tag: SessionTag) {
		
		self.chatID = chatID
		self.tag = tag
		
		self.addEvent = schedule.add(_:)
		self.removeEvent = schedule.remove(_:)
	}
	
	/** 
	Adds an action to the session queue, that allows an enclosure to be executed at a later time, with the included session.
	- parameter byDelay: The time this action has to wait from when the last action was executed.  If queued after an action that has a defined
	`viewTime` thats longer than they delay, that will be used as the time that this action can be sent as one in the stack before it.
	- parameter viewTime: The length of the pause after this action is executed before another action in the queue can be executed.
	If the action next in the stack has a delay timer thats longer, that will be used instead as the pause between the two actions.
	- parameter name: A name for the action, that can be used to search for and edit the action later on.
	- parameter action: The closure to be executed when the queue executes this action.
	*/
	public func action(delay: Duration, viewTime: Duration, action: @escaping () -> ()) -> ScheduleEvent {
		
		// Calculate what kind of delay we're using
		let execTime = bumpEventTime(delay: delay, viewTime: viewTime)
		
		
		// Add it directly to the end of the stack
		let event = ScheduleEvent(delayUnixTime: execTime, action: action)
		addEvent(event)
		eventHistory.append(event)
		
		return event
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
	public func message(delay: Duration, viewTime: Duration, message: String, markup: MarkupType? = nil) {
		
		// Calculate what kind of delay we're using
		let execTime = bumpEventTime(delay: delay, viewTime: viewTime)
		
		let event = ScheduleEvent(delayUnixTime: execTime) {
			
			let request = TelegramRequest.sendMessage(chatID: self.chatID, text: message, replyMarkup: markup	)
			_ = self.tag.sendRequest(request)
		}
		
		addEvent(event)
		eventHistory.append(event)
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
	public func messageEx(delay: Duration, viewTime: Duration, message: String, markup: MarkupType? = nil, parseMode: MessageParseMode = .none, replyID: Int = 0, webPreview: Bool = false, disableNtf: Bool = false) {
		
		// Calculate what kind of delay we're using
		let execTime = bumpEventTime(delay: delay, viewTime: viewTime)
		
		let event = ScheduleEvent(delayUnixTime: execTime) {
			
			let request = TelegramRequest.sendMessage(chatID: self.chatID, text: message, replyMarkup: markup, parseMode: parseMode, disableWebPreview: webPreview, disableNtf: disableNtf, replyMessageID: replyID)
			_ = self.tag.sendRequest(request)
		}
		
		addEvent(event)
		eventHistory.append(event)
	}
	
	
	/// Properly calculates a wait time to send a message based on a pause and the previous dialog length.
	public func dialog(delay: Int, dialog: String, markup: MarkupType? = nil) {
		
		let viewTime = calculateReadTime(text: dialog)
		
		// Calculate what kind of delay we're using
		let execTime = bumpEventTime(delay: (viewTime + delay).seconds, viewTime: 0.seconds)
		
		let event = ScheduleEvent(delayUnixTime: execTime) {
			let request = TelegramRequest.sendMessage(chatID: self.chatID, text: dialog, replyMarkup: markup	)
			_ = self.tag.sendRequest(request)
		}
		
		addEvent(event)
		eventHistory.append(event)
	}
	
	func bumpEventTime(delay: Duration, viewTime: Duration) -> Double {
		
		// Calculate what kind of delay we're using
		var execTime = lastEventTime + lastEventViewTime
		
		// If we have a last event view time that is shorter than the delay, extend the execTime by this.
		if (lastEventViewTime - delay.unixTime) > 0 {
			execTime += lastEventViewTime - delay.unixTime
		}
		
		// Otherwise just add the delay directly
		else {
			execTime += delay.unixTime
		}
		
		
		// Set the new last timer values
		lastEventTime = execTime
		lastEventViewTime = viewTime.unixTime
		
		return execTime
	}
	
	/** Calculates a read time for dialog-specific queue functions */
	func calculateReadTime(text: String) -> Int {
		let wordsPerMinute = 250
		
		let wordCount = text.components(separatedBy: NSCharacterSet.whitespaces).count
		let readTime = Int(ceil(Float(wordCount) / Float(wordsPerMinute / 60)))
		return Int(readTime)
	}
	
	/**
	Removes a scheduled event from being executed.
	*/
	public func remove(_ event: ScheduleEvent) {
		
		removeEvent(event)
	}
	
	/** Clears all actions in the queue. */
	public func clear() {
		lastEventTime = 0
		lastEventViewTime = 0
		
		for event in eventHistory {
			_ = removeEvent(event)
		}
		
		eventHistory.removeAll()
	}
}

