//
//  ChatSessionActions.swift
//  Pelican
//
//  Created by Takanu Kyriako on 27/03/2017.
//
//

import Foundation


/** 
Defines a class that acts as a proxy for the Pelican-managed Schedule class, used to delay the execution
of closures and API requests.

When a closure or API request is delayed, it will still be executed on the DispatchQueue belonging to the Session
that called it, ensuring thread safety.
*/
public class ChatSessionQueue {
	
	/// DATA
	/// The chat ID of the session this queue belongs to.
	public var chatID: String
	
	/// A callback to the Pelican `sendRequest` method, enabling the class to send it's own requests.
	public var tag: SessionTag
	
	// CALLBACKS
	/// A callback to Schedule, to add an event to the queue.
	public var addEvent: (ScheduleEvent) -> ()
	
	public var removeEvent: (ScheduleEvent) -> ()
	
	
	/** 
	Copies of the ScheduleEvents that are generated to submit to the schedule, in case this class needs to remove
	any events already in the schedule.
	*/
	public var eventHistory: [ScheduleEvent] = []
	
	/// The point at which the last addition to the queue is set to play, relative to the current time value.
	var lastEventTime: Double = 0
	
	/// The last event "view time" request, used to calculate when the next event should be queued at.
	var lastEventViewTime: Double = 0
	

	
	/**
	Initialises the Queue class with a Pelican-derived Schedule.
	*/
	public init(chatID: String, schedule: Schedule, tag: SessionTag) {
		
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
	@discardableResult
	public func action(delay: Duration, viewTime: Duration, action: @escaping () -> ()) -> ScheduleEvent {
		
		// Calculate what kind of delay we're using
		let execTime = bumpEventTime(delay: delay, viewTime: viewTime)
		
		
		// Add it directly to the end of the stack
		let event = ScheduleEvent(tag: tag, delayUnixTime: execTime, action: action)
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
	public func message(delay: Duration, viewTime: Duration, message: String, markup: MarkupType? = nil, chatID: Int) {
		
		// Calculate what kind of delay we're using
		let execTime = bumpEventTime(delay: delay, viewTime: viewTime)
		
		let event = ScheduleEvent(tag: tag, delayUnixTime: execTime) {
			
			let request = TelegramRequest.sendMessage(chatID: chatID, text: message, markup: markup	)
			_ = self.tag.sendSyncRequest(request)
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
	public func messageEx(delay: Duration,
												viewTime: Duration,
												message: String,
												markup: MarkupType? = nil,
												chatID: Int,
												parseMode: MessageParseMode = .none,
												replyID: Int = 0,
												useWebPreview: Bool = false,
												disableNotification: Bool = false) {
		
		// Calculate what kind of delay we're using
		let execTime = bumpEventTime(delay: delay, viewTime: viewTime)
		
		let event = ScheduleEvent(tag: tag, delayUnixTime: execTime) {
			
			let request = TelegramRequest.sendMessage(chatID: chatID, text: message, markup: markup, parseMode: parseMode, disableWebPreview: useWebPreview, disableNotification: disableNotification, replyMessageID: replyID)
			_ = self.tag.sendSyncRequest(request)
		}
		
		addEvent(event)
		eventHistory.append(event)
	}
	
	/**
	Used to internally bump the queue stack timer, to ensure that when actions are queued they never overlap each other.
	
	Only use this for custom functions that extend Queue, all default queue action functions already make use of this.
	*/
	public func bumpEventTime(delay: Duration, viewTime: Duration) -> Double {
		
		// Calculate what kind of delay we're using
		var execTime = lastEventTime
		
		// If we have a last event view time that is longer than the delay, extend the execTime by this.
		if (lastEventViewTime - delay.unixTime) > 0 {
			execTime += lastEventViewTime
		}
		
		// Otherwise just add the delay directly
		else {
			execTime += delay.unixTime
		}
		
		//print("Event time bumped - (delay \(delay) | viewTime \(viewTime)) (LETime- \(lastEventTime) | LEViewTime - \(lastEventViewTime)) \(execTime) seconds, ")
		
		
		// Set the new last timer values
		lastEventTime = execTime
		lastEventViewTime = viewTime.unixTime
		
		return execTime
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
		
		//print("Event queue cleared.")
		
		for event in eventHistory {
			_ = removeEvent(event)
		}
		
		eventHistory.removeAll()
	}
}

