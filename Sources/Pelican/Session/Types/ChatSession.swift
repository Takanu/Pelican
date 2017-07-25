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
	public var builderID: Int
	public var tag: SessionTag
	
	/// The chat ID associated with the session.
	var chatID: Int
	public var getChatID: Int { return chatID }
	
	/// The chat associated with the session, if one exists.
	var chat: Chat?
	public var getChat: Chat? { return chat }
	
	
	
	/// API REQUESTS
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
	
	/// Stores what Moderator-controlled permissions the Chat Session has.
	public var permissions: Permissions
	
	/// Stores a link to the schedule, that allows events to be executed at a later date.
	public var schedule: Schedule
	
	/// Handles timeout conditions.
	public var timeout: TimeoutController
	
	/// Handles flood conditions.
	public var flood: FloodController
	
	
	
	// MAINTENANCE
	
	/// A command to be used when the session ends.
	public var sessionEndAction: ((ChatSession) -> ())?
	
	
	// Time and Activity
	public var timeStarted = Date()
	
	
	// STORED UPDATES
	public var currentMessage: Message?
	public var lastSentMessage: Message?
	public var wordsPerMinute: Int = 190      // Used as an implicit timer for a set of dialog actions.
	
	
	// Setup the session by passing a function that modifies itself with the required commands.
	public required init(bot: Pelican, builder: SessionBuilder, update: Update) {
		
		self.builderID = builder.getID
		self.tag = SessionTag(sessionID: update.chat!.tgID, builderID: builder.getID, request: bot.sendRequest(_:), event: bot.sendEvent(_:))
		
		self.chatID = update.chat!.tgID
		self.prompts = PromptController()
		self.queue = ChatSessionQueue(chatID: update.chat!.tgID, schedule: bot.schedule, tag: self.tag)
		self.routes = RouteController()
		
		self.permissions = bot.mod.getPermissions(chatID: self.chatID)
		self.schedule = bot.schedule
		self.timeout = TimeoutController(tag: self.tag, schedule: self.schedule)
		self.flood = FloodController()
		
		self.send = TGSend(chatID: self.chatID, tag: tag)
		self.admin = TGAdmin(chatID: self.chatID, tag: tag)
		self.edit = TGEdit(chatID: self.chatID, tag: tag)
		self.answer = TGAnswer(tag: tag)
	}
	
	open func postInit() {
		prompts.session = self
	}
	
	open func setupRemoval() {
		self.queue.clear()
		
		// Need something for prompt, do it with the refactor
	}
	
	
	// Receives a message from the TelegramBot to check whether in the current state anything can be done with it
	public func update(_ update: Update) {
		
		// This needs revising, whatever...
		let handled = routes.routeRequest(update: update, type: update.type)
		
		if handled == false && update.type == .callbackQuery {
			_ = prompts.filterQuery(update.data as! CallbackQuery, session: self)
		}
		
		// Bump the flood and timeout controllers
		flood.bump(update)
		timeout.bump(update)
		
	}
}
