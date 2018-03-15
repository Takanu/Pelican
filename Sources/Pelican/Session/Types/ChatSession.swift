//
//  ChatSession.swift
//  party
//
//  Created by Takanu Kyriako on 02/07/2017.
//
//

import Foundation
import Vapor
import FluentProvider

/**
Holds the information for a bot session, when someone is immediately interacting with the bot
Ignore this if you want?  What am i, a doctor?
*/
open class ChatSession: Session {
	
	public var tag: SessionTag
	public var dispatchQueue: SessionDispatchQueue
	
	
	/// The chat ID associated with the session.
	var chatID: Int
	public var getChatID: Int { return chatID }
	
	/// The chat associated with the session, if one exists.
	var chat: Chat?
	public var getChat: Chat? { return chat }
	
	
	// API REQUESTS
	// Shortcuts for API requests.
	public var requests: SessionRequests
	
	
	// DELEGATES AND CONTROLLERS
	/// Handler for delayed Telegram API calls and closure execution.
	public var queue: ChatSessionQueue
	
	/// Handles and matches user requests to available bot functions.
	public var baseRoute: Route
	
	/// Stores what Moderator-controlled titles the Chat Session has.
	public var mod: SessionModerator
	
	/// Handles timeout conditions.
	public var timeout: Timeout
	
	/// Handles flood conditions.
	public var flood: Flood
	
	
	// MAINTENANCE
	/// A command to be used when the session ends.
	public var sessionEndAction: ((ChatSession) -> ())?
	
	// Time and Activity
	public var timeStarted = Date()
	
	
	// Setup the session by passing a function that modifies itself with the required commands.
	public required init(bot: Pelican, tag: SessionTag, update: Update) {
		
		self.tag = tag
		self.chat = update.chat!
		self.chatID = update.chat!.tgID
		
		self.queue = ChatSessionQueue(chatID: update.chat!.tgID, schedule: bot.schedule, tag: self.tag)
		self.baseRoute = Route(name: "base", routes: [])
		
		self.mod = SessionModerator(tag: tag, moderator: bot.mod)!
		self.timeout = Timeout(tag: self.tag, schedule: bot.schedule)
		self.flood = Flood()
		
		self.requests = SessionRequests(tag: tag)
		self.dispatchQueue = SessionDispatchQueue(tag: tag, label: "pelican.chatsession",qos: .userInitiated)
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
	}
	
	
	// Receives a message from the TelegramBot to check whether in the current state anything can be done with it
	public func update(_ update: Update) {
		
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
