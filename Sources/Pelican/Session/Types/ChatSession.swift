//
//  ChatSession.swift
//  party
//
//  Created by Takanu Kyriako on 02/07/2017.
//
//

import Foundation

/**
Holds the information for a bot session, when someone is immediately interacting with the bot
Ignore this if you want?  What am i, a doctor?
*/
open class ChatSession: Session {
	
	public private(set) var tag: SessionTag
	public private(set) var dispatchQueue: SessionDispatchQueue
	
	/// The chat ID associated with the session.
	public private(set) var chatID: String
	
	/// The chat associated with the session, if one exists.
	public private(set) var chat: Chat?
	
	
	// API REQUESTS
	// Shortcuts for API requests.
	public private(set) var requests: MethodRequest
	
	
	// DELEGATES AND CONTROLLERS
	/// Handler for delayed Telegram API calls and closure execution.
	public private(set) var queue: ChatSessionQueue
	
	/// Delegate for creating, modifying and getting other Sessions.
	public private(set) var sessions: SessionRequest
	
	/// Handles and matches user requests to available bot functions.
	public var baseRoute: Route
	
	/// Stores what Moderator-controlled titles the Chat Session has.
	public private(set) var mod: SessionModerator
	
	/// Handles timeout conditions.
	public private(set) var timeout: TimeoutMonitor
	
	/// Handles flood conditions.
	public private(set) var flood: FloodMonitor
	
	/// Pre-checks and filters unnecessary updates.
	public private(set) var filter: UpdateFilter
	
	
	// MAINTENANCE
	/// A command to be used when the session ends.
	public var sessionEndAction: ((ChatSession) -> ())?
	
	// TIME AND ACTIVITY
	public var timeStarted = Date()
	
	
	// Setup the session by passing a function that modifies itself with the required commands.
	public required init?(bot: PelicanBot, tag: SessionTag) {
		
		if tag.chat == nil { return nil }
		
		self.tag = tag
		self.chat = tag.chat!
		self.chatID = tag.chat!.tgID
		
		self.queue = ChatSessionQueue(chatID: tag.chat!.tgID, schedule: bot.schedule, tag: self.tag)
		self.sessions = SessionRequest(bot: bot)
		self.baseRoute = Route(name: "base", routes: [])
		
		self.mod = SessionModerator(tag: tag, moderator: bot.mod)!
		self.timeout = TimeoutMonitor(tag: self.tag, schedule: bot.schedule)
		self.flood = FloodMonitor()
		self.filter = UpdateFilter()
		
		self.requests = MethodRequest(tag: tag)
		self.dispatchQueue = SessionDispatchQueue(tag: tag, label: "com.pelican.chatsession_\(tag.sessionID)",qos: .userInitiated)
	}
	
	open func postInit() {
		
	}
	
	open func cleanup() {
		
		// Clear all properties
		self.queue.clear()
		self.baseRoute.close()
		self.timeout.close()
		self.flood.clearAll()
		self.dispatchQueue.cancelAll()
		self.filter.reset()
	}
	
	
	// Receives a message from the TelegramBot to check whether in the current state anything can be done with it
	public func update(_ update: Update) {
		
		if filter.verifyUpdate(update) == false {
			self.timeout.bump(update)
			self.flood.handle(update)
			return
		}
		
		dispatchQueue.async {
			// Bump the timeout controller first so if flood or another process closes the Session, a new timeout event will not be added.
			self.timeout.bump(update)
			
			// This needs revising, whatever...
			_ = self.baseRoute.handle(update)
			
			// Pass the update to the flood controller to be handled.
			self.flood.handle(update)
		}
		
	}
}
