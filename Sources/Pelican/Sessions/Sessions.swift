
import Foundation
import Vapor
import FluentProvider

/** 
Holds the information for a bot session, when someone is immediately interacting with the bot
Ignore this if you want?  What am i, a doctor?
*/
public class ChatSession {
	
	/// Database storage for compatibility with Model in FluentProvider.
  public var storage = Storage()
	
	
	// CORE TYPES
	
	/// The bot associated with this session, used internally to access the Telegram API.
  public var bot: Pelican
	
	/// The chat ID associated with the session.
	public var chatID: Int
	
	/// The chat associated with the session, if one exists.
  public var chat: Chat?
	
	/** A user-defined type assigned by Pelican on creation, used to cleanly associate custom functionality and
	variables to an individual session.
	*/
	public var data: NSCopying?
	
	
	
	// DELEGATES AND CONTROLLERS
	
	/// Container for automating markup options and responses.
  public var prompts: PromptController
	
	/// Handler for delayed Telegram API calls and closure execution.
	public var queue: ChatSessionQueue
	
	/// Handles and matches user requests to available bot functions.
	public var routes: RouteController<ChatUpdateType, ChatSession, ChatUpdate>
	
	/// Stores what Moderator-controlled permissions the Chat Session has.
	var permissions: [String] = []
	
	/// Stores what Moderator-controlled permissions the Chat Session has.  To edit them, use `Pelican.mod`.
	public var getPermissions: [String] { return permissions }
	
	
	
	// MAINTENANCE
	
	/// A command to be used when the session ends.
	public var sessionEndAction: ((ChatSession) -> ())?
	
	
  
  // CHATSESSION SETTINGS
	
	// What the current maximum for the session time is.  Set 0 for no timer.
  var maxChatSessionTime: Int = 0
	
	// The last time the session was interacted with.
  internal var lastInteractTime: Int = 0
	
	// Checks whether or not this session has timed out.
  var timedOut: Bool { return lastInteractTime <= bot.globalTimer - maxChatSessionTime }
	
	
  // RESPONSE SETTINGS
  var responseLimit: Int = 0					// The number of times a session will respond in a given timeframe.  Set as 0 for no limit.
  private var responseCount: Int = 0	// The number of times a response has been made in the timeframe.
  private var responseTime: Int = 0		// The time at which the last response has been made (in bot time).
	
  
  // STORED UPDATES
  public var currentMessage: Message?
  public var lastSentMessage: Message?
  var lastDialog: String = ""               // A way to use the last given piece of dialog as a delay timer for the next.
  var plusTimer: Int = 0                    // A way to allow sequentially stated delays to naturally stack up.
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
    
    // Set the timers
    self.maxChatSessionTime = bot.defaultMaxChatSessionTime
    self.lastInteractTime = bot.globalTimer
    
    setup(self)
  }
  
  func postInit() {
    prompts.session = self
		queue.session = self
  }
	
  
  // Receives a message from the TelegramBot to check whether in the current state anything can be done with it
  func filterUpdate(_ update: ChatUpdate) {
		
		// This needs revising, whatever...
		_ = routes.routeRequest(update: update, type: .message, session: self)
		
		/*
		if update.data is Message {
			filterMessage(message: update.data as! Message)
		}
		
		else if update.data is CallbackQuery {
			filterCallbackQuery(query: update.data as! CallbackQuery)
		}
		*/
  }
	
	/*
	
	private func filterMessage(message: Message) {
		
		// Set the current message
		currentMessage = message
		
		// If the response time doesn't match, we're responding to a new batch of messages, so reset it.
		if bot.globalTimer != responseTime {
			responseTime = bot.globalTimer
			responseCount = 0
		}
		
		// If we haven't yet reached our response limit, send a request for the update to be routed
		if responseCount < responseLimit && responseLimit != 0 {
			_ = routes.routeRequest(update: message as! UpdateModel, type: .message, session: self)
		}
		
		responseCount += 1
	}
	
	
  private func filterCallbackQuery(query: CallbackQuery) {
    
    // Send a route request
    let handled = routes.routeRequest(update: query as! UpdateModel, type: .callbackQuery, session: self)
    
    if handled == false {
      let promptHandled = prompts.filterQuery(query, session: self)
			
			// If this wasn't handled, send a blank response to avoid the INFINITE LOADING ICON.
			if promptHandled == false {
				answerCallbackQuery(queryID: query.id, text: "")
			}
    }
  }
	
	*/
	
	
  ////////////////////////////////////////////////////
  //////////// CONVENIENCE API METHODS
	
	/**
	Sends a text-based message to the chat linked to this session.
	*/
	public func sendMessage(_ message: String, markup: MarkupType?, reply: Bool, parseMode: MessageParseMode = .markdown, webPreview: Bool, disableNtf: Bool) -> Message? {
		
		if currentMessage != nil {
			
			var makeReply = 0
			if reply == true {
				makeReply = currentMessage!.tgID
			}
			
			let message = bot.sendMessage(chatID: chatID, text: message, replyMarkup: markup, parseMode: parseMode, disableWebPreview: webPreview, disableNtf: disableNtf, replyMessageID: makeReply)
			self.lastSentMessage = message
			return message
		}
		else { return nil }
	}
	
	
	/**
	Sends a file as a message to the chat linked to this session.
	*/
	public func sendFile(_ file: SendType, caption: String = "", markup: MarkupType?, replyID: Int, disableNtf: Bool) -> Message? {
		
		let message = bot.sendFile(chatID: chatID, file: file, replyMarkup: markup, caption: caption, disableNtf: disableNtf, replyMessageID: replyID)
		self.lastSentMessage = message
		return message
	}
	
	
	
	/**
	Sends and uploads a file as a message to the chat linked to this session, using a `FileLink`
	*/
	public func uploadFile(_ link: FileLink, caption: String = "", markup: MarkupType?, replyID: Int, disableNtf: Bool, callback: ReceiveUpload? = nil) {
		
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
  
  /// Alters the maximum session time given.  DOESNT WORK YET PLZ NO.  Will also bump the session
  internal func changeChatSessionTime(_ time: Int) {
    self.maxChatSessionTime = time
    bot.bumpChatSession(self)
  }
}




