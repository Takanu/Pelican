//
//  ChatSession.swift
//  party
//
//  Created by Ido Constantine on 02/07/2017.
//
//

import Foundation
import Vapor

/**
Holds the information for a bot session, when someone is immediately interacting with the bot
Ignore this if you want?  What am i, a doctor?
*/
public class ChatSession: Session {
	
	/// Database storage for compatibility with Model in FluentProvider.
	public var storage = Storage()
	
	
	// CORE TYPES
	public var bot: Pelican
	public var data: NSCopying?
	
	/// The chat ID associated with the session.
	public var chatID: Int
	
	/// The chat associated with the session, if one exists.
	public var chat: Chat?
	
	
	
	// DELEGATES AND CONTROLLERS
	
	/// Container for automating markup options and responses.
	public var prompts: PromptController
	
	/// Handler for delayed Telegram API calls and closure execution.
	public var queue: ChatSessionQueue
	
	/// Handles and matches user requests to available bot functions.
	public var routes: RouteController<ChatUpdateType, ChatSession, ChatUpdate>
	
	/// Stores what Moderator-controlled permissions the Chat Session has.
	var permissions: [String] = []
	
	
	
	// MAINTENANCE
	
	/// A command to be used when the session ends.
	public var sessionEndAction: ((ChatSession) -> ())?
	
	
	// Time and Activity
	public var timeStarted = Date()
	var timeLastActive = Date()
	
	var timeoutLength: Int {
		get {
			return self.timeoutLength
		}
		
		set(newTimeout) {
			
			// If the new timeout is a usable number, add it to the sessions that need their activity checked.
			if timeoutLength <= 0 && newTimeout > 0 {
				self.timeoutLength = newTimeout
				bot.chatSessionActivity[chatID] = self
			}
				
				// If the number has been zeroed out, remove it from the activity list.
			else if timeoutLength > 0 && newTimeout <= 0 {
				self.timeoutLength = newTimeout
				bot.chatSessionActivity.removeValue(forKey: chatID)
			}
		}
	}
	
	
	// STORED UPDATES
	public var currentMessage: Message?
	public var lastSentMessage: Message?
	public var wordsPerMinute: Int = 190      // Used as an implicit timer for a set of dialog actions.
	
	
	// Setup the session by passing a function that modifies itself with the required commands.
	public init(bot: Pelican, chatID: Int, data: NSCopying?, floodLimit: FloodLimit, setup: @escaping (ChatSession) -> (), sessionEndAction: ((ChatSession) -> ())? ) {
		self.bot = bot
		self.chatID = chatID
		self.prompts = PromptController()
		self.queue = ChatSessionQueue()
		self.routes = RouteController()
		
		if data != nil {
			self.data = data!.copy() as? NSCopying
		}
		
		if sessionEndAction != nil {
			self.sessionEndAction = sessionEndAction!
		}
		
		setup(self)
	}
	
	func postInit() {
		prompts.session = self
		queue.session = self
	}
	
	
	// Receives a message from the TelegramBot to check whether in the current state anything can be done with it
	func filterUpdate(_ update: ChatUpdate) {
		
		// This needs revising, whatever...
		let handled = routes.routeRequest(update: update, type: .message, session: self)
		
		if handled == false && update.type == .callbackQuery {
			_ = prompts.filterQuery(update.data as! CallbackQuery, session: self)
		}
		
		// Bump the timeout
		timeLastActive = Date()
		
	}
	
	
	////////////////////////////////////////////////////
	//////////// CONVENIENCE API METHODS
	
	/**
	Sends a text-based message to the chat linked to this session.
	*/
	public func sendMessage(_ message: String, markup: MarkupType?, parseMode: MessageParseMode = .markdown, replyID: Int = 0, webPreview: Bool = false, disableNtf: Bool = false) -> Message? {
		
		let message = bot.sendMessage(chatID: chatID, text: message, replyMarkup: markup, parseMode: parseMode, disableWebPreview: webPreview, disableNtf: disableNtf, replyMessageID: replyID)
		self.lastSentMessage = message
		return message
	}
	
	
	/**
	Sends a file as a message to the chat linked to this session.
	*/
	public func sendFile(_ file: SendType, caption: String, markup: MarkupType?, replyID: Int = 0, disableNtf: Bool = false) -> Message? {
		
		let message = bot.sendFile(chatID: chatID, file: file, replyMarkup: markup, caption: caption, disableNtf: disableNtf, replyMessageID: replyID)
		self.lastSentMessage = message
		return message
	}
	
	
	
	/**
	Sends and uploads a file as a message to the chat linked to this session, using a `FileLink`
	*/
	public func uploadFile(_ link: FileLink, caption: String, markup: MarkupType?, replyID: Int = 0, disableNtf: Bool = false, callback: ReceiveUpload? = nil) {
		
		bot.uploadFile(link: link, callback: callback, chatID: chatID, markup: markup, caption: caption, disableNtf: disableNtf, replyMessageID: replyID)
	}
	
	
	/**
	Edits a text-based or game message with replacement text and markup options.
	*/
	public func editMessage(withMessageID messageID: Int, text: String, markup: MarkupType?, parseMode: MessageParseMode = .markdown, webPreview: Bool) {
		
		bot.editMessageText(chatID: chatID, messageID: messageID, text: text, replyMarkup: markup, parseMode: parseMode, disableWebPreview: webPreview)
	}
	
	/**
	Edits a text-based or game message with replacement text and markup options (NEED TO FINISH THIS, DOESNT WORK YET).
	- parameter withInlineMessageID: The identifier of the inline message you wish to edit.
	- parameter text: The text you wish to use as the message body.  This will replace any pre-existing text in the message.
	- parameter markup: The inline markup keyboard you wish to use as a replacement to the one currently on the message, if any.
	*/
	public func editMessage(withInlineMessageID inlineID: Int, text: String, markup: MarkupType?, parseMode: MessageParseMode = .markdown, webPreview: Bool) {
		
		bot.editMessageText(inlineMessageID: inlineID, text: text, replyMarkup: markup, parseMode: parseMode, disableWebPreview: webPreview)
	}
	
	/**
	Edits a file-based message with replacement text and markup options.
	*/
	public func editCaption(withMessageID messageID: Int, caption: String, markup: MarkupType?) {
		
		bot.editMessageCaption(chatID: chatID, messageID: messageID, caption: caption, replyMarkup: markup)
	}
	
	/**
	Responds to a callback query, generated from an inline keyboard.
	- note: A session will always provide a blank fallback response if a callback query is not answered in any of your routes (by returning false).
	*/
	public func answerCallbackQuery(queryID: String, text: String, popup: Bool = false, gameURL: String = "") {
		
		bot.answerCallbackQuery(queryID: queryID, text: text, showAlert: popup, url: gameURL, cacheTime: 0)
	}
	
}
