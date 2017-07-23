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
	
	/// The chat ID associated with the session.
	public var chatID: Int
	
	/// The chat associated with the session, if one exists.
	public var chat: Chat?
	
	
	
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
	
	
	// CALLBACKS
	public var sendRequest: (TelegramRequest) -> (TelegramResponse)
	public var sendEvent: (SessionEvent) -> ()
	
	
	
	// MAINTENANCE
	
	/// A command to be used when the session ends.
	public var sessionEndAction: ((ChatSession) -> ())?
	
	
	// Time and Activity
	public var timeStarted = Date()
	public var timeLastActive = Date()
	
	public var timeoutLength: Int = 0
	
	
	// STORED UPDATES
	public var currentMessage: Message?
	public var lastSentMessage: Message?
	public var wordsPerMinute: Int = 190      // Used as an implicit timer for a set of dialog actions.
	
	
	// Setup the session by passing a function that modifies itself with the required commands.
	public required init(bot: Pelican, builder: SessionBuilder, update: Update) {
		
		self.builderID = builder.getID
		
		self.chatID = update.chat!.tgID
		self.prompts = PromptController()
		self.queue = ChatSessionQueue(chatID: update.chat!.tgID, schedule: bot.schedule, request: bot.sendRequest(_:))
		self.routes = RouteController()
		
		self.permissions = bot.mod.getPermissions(chatID: self.chatID)
		self.schedule = bot.schedule

		self.sendRequest = bot.sendRequest(_:)
		self.sendEvent = bot.sendEvent(_:)
		
		self.send = TGSend(chatID: self.chatID, sendRequest: bot.sendRequest(_:))
		self.admin = TGAdmin(chatID: self.chatID, sendRequest: bot.sendRequest(_:))
		self.edit = TGEdit(chatID: self.chatID, sendRequest: bot.sendRequest(_:))
		self.answer = TGAnswer(sendRequest: bot.sendRequest(_:))
	}
	
	open func postInit() {
		prompts.session = self
	}
	
	
	// Receives a message from the TelegramBot to check whether in the current state anything can be done with it
	public func update(_ update: Update) {
		
		// This needs revising, whatever...
		let handled = routes.routeRequest(update: update, type: update.type, session: self)
		
		if handled == false && update.type == .callbackQuery {
			_ = prompts.filterQuery(update.data as! CallbackQuery, session: self)
		}
		
		// Bump the timeout
		timeLastActive = Date()
		
	}
}
