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
	
	/// Database storage for compatibility with Model in FluentProvider.
	public var storage = Storage()
	
	// CORE TYPES
	public var tag: SessionTag
	
	/// The chat ID associated with the session.
	var chatID: Int
	public var getChatID: Int { return chatID }
	
	/// The chat associated with the session, if one exists.
	var chat: Chat?
	public var getChat: Chat? { return chat }
	
	
	// API REQUESTS
	// Shortcuts for API requests.
	public var send: TGSend
	public var admin: TGAdmin
	public var edit: TGEdit
	public var answer: TGAnswer
	
	
	// DELEGATES AND CONTROLLERS
	/// Container for automating markup options and responses.
	public var prompts: PromptController
	
	/// Handler for delayed Telegram API calls and closure execution.
	public var queue: ChatSessionQueue
	
	/// Handles and matches user requests to available bot functions.
	public var routes: RouteController
	
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
		
		self.prompts = PromptController(tag: tag, schedule: bot.schedule)
		self.queue = ChatSessionQueue(chatID: update.chat!.tgID, schedule: bot.schedule, tag: self.tag)
		self.routes = RouteController()
		
		self.mod = SessionModerator(tag: tag, moderator: bot.mod)!
		self.timeout = Timeout(tag: self.tag, schedule: bot.schedule)
		self.flood = Flood()
		
		self.send = TGSend(chatID: self.chatID, tag: tag)
		self.admin = TGAdmin(chatID: self.chatID, tag: tag)
		self.edit = TGEdit(chatID: self.chatID, tag: tag)
		self.answer = TGAnswer(tag: tag)
	}
	
	open func postInit() {
		
	}
	
	open func cleanup() {
		self.queue.clear()
		self.timeout.close()
		self.queue.clear()
	}
	
	
	// Receives a message from the TelegramBot to check whether in the current state anything can be done with it
	public func update(_ update: Update) {
		
		// Bump the timeout controller first so if flood or another process closes the Session, a new timeout event will not be added.
		timeout.bump(update)
		
		// This needs revising, whatever...
		let handled = routes.handle(update: update)
		
		if handled == false {
			_ = prompts.handle(update)
		}
		
		// Bump the flood controller after
		flood.bump(update)
		
	}
}
