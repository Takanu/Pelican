
import Foundation
import Vapor
import FluentProvider

// Holds the information for a bot session, when someone is immediately interacting with the bot
// Ignore this if you want?  What am i, a doctor?
public class Session {
  public var storage = Storage()          // Database ID
	
	// Core Types
  public var bot: Pelican        // The bot associated with this session
  public var chat: Chat          // The chat ID associated with the session.
  public var primaryUser : User? // The primary user associated with this session, not applicable for channels or potentially other things.
  public var users: [User] = []  // Other users associated with this session.  The primary user is likely in this list.
  public var data: NSCopying?    // User-defined data chunk.
	
	// Delegates/Controllers
  public var prompts: PromptController    // Container for automating markup options and responses.
	public var queue: SessionQueue	//	Handler for delayed Telegram API calls and closure execution.
	public var routes: RouteController		// Handles and matches user requests to available bot functions.
	
	// Maintenance
	var floodLimit: FloodLimit     // External flood tracking system.
	public var sessionEndAction: ((Session) -> ())? // A command to be used when the session ends.
	
  
  // Session settings
  var maxSessionTime: Int = 0 // What the current maximum for the session time is.  Set 0 for no timer.
  internal var lastInteractTime: Int = 0 // The last time the session was interacted with.
  var timedOut: Bool { return lastInteractTime <= bot.globalTimer - maxSessionTime }  // Checks whether or not this session has timed out.
	
	
  // Response Settings
  var responseLimit: Int = 0 // The number of times a session will respond in a given timeframe.  Set as 0 for no limit.
  private var responseCount: Int = 0 // The number of times a response has been made in the timeframe.
  private var responseTime: Int = 0 // The time at which the last response has been made (in bot time).
  
	
//  var actionQueue: [QueueAction] = [] // Any queued actions that need to be monitored.
	
  
  // Stored requests
  public var currentMessage: Message?
  public var lastSentMessage: Message?
  var lastDialog: String = ""               // A way to use the last given piece of dialog as a delay timer for the next.
  var plusTimer: Int = 0                    // A way to allow sequentially stated delays to naturally stack up.
  public var wordsPerMinute: Int = 190      // Used as an implicit timer for a set of dialog actions.
  
  
  // Setup the session by passing a function that modifies itself with the required commands.
  public init(bot: Pelican, chat: Chat, data: NSCopying?, floodLimit: FloodLimit, setup: @escaping (Session) -> (), sessionEndAction: ((Session) -> ())? ) {
    self.bot = bot
    self.chat = chat
    self.prompts = PromptController()
		self.queue = SessionQueue()
		self.routes = RouteController()
		
    self.floodLimit = FloodLimit(clone: floodLimit) // A precaution to only copy the range values
    
    if data != nil {
      self.data = data!.copy() as? NSCopying
    }
    
    if sessionEndAction != nil {
      self.sessionEndAction = sessionEndAction!
    }
    
    // Set the timers
    self.maxSessionTime = bot.defaultMaxSessionTime
    self.lastInteractTime = bot.globalTimer
    
    setup(self)
  }
  
  func postInit() {
    prompts.session = self
		queue.session = self
  }
  
  // Functions for managing what users are associated to this session.
  public func hasUser(_ user: User) -> Bool {
    if users.count == 0 { return false }
    if users.contains(where: { $0.tgID == user.tgID } ) == true { return true }
    return false
  }
  
  public func addUser(_ user: User) {
    users.append(user)
  }
	
	
  
  // Receives a message from the TelegramBot to check whether in the current state anything can be done with it
  func filterUpdate(message: Message) {
    
    // Set the current message
    currentMessage = message
		
		// If the response time doesn't match, we're responding to a new batch of messages, so reset it.
		if bot.globalTimer != responseTime {
			responseTime = bot.globalTimer
			responseCount = 0
		}
		
		// If we haven't yet reached our response limit, send a request for the update to be routed
		if responseCount < responseLimit && responseLimit != 0 {
			_ = routes.routeRequest(content: message, type: .message, session: self)
		}
		
		responseCount += 1
    
    // Check the flood status
    bumpFlood()
  }
  
  func filterInlineQuery(query: InlineQuery) {
    
    // Send a route request
		_ = routes.routeRequest(content: query, type: .inlineQuery, session: self)
    
    // Check the flood status
    bumpFlood()
  }
  
  func filterInlineResult(query: ChosenInlineResult) {
    
    // Send a route request
    _ = routes.routeRequest(content: query, type: .chosenInlineResult, session: self)
    
    // Check the flood status
    bumpFlood()
  }
  
  func filterCallbackQuery(query: CallbackQuery) {
    
    // Send a route request
    let handled = routes.routeRequest(content: query, type: .callbackQuery, session: self)
    
    if handled == false {
      prompts.filterQuery(query, session: self)
    }
    
    // Check the flood status
    bumpFlood()
  }
	
	
	
	
  ////////////////////////////////////////////////////
  //////////// NORMAL SEND REQUESTS
  
  
  // Sends a normal message.  A convenience method to keep core program code clean.
  public func send(message: String, markup: MarkupType? = nil, reply: Bool = false, parseMode: MessageParseMode = .markdown, webPreview: Bool = false, disableNtf: Bool = false) -> Message? {
    if currentMessage != nil {
      
      var makeReply = 0
      if reply == true {
        makeReply = currentMessage!.tgID
      }
      
      let message = bot.sendMessage(chatID: chat.tgID, text: message, replyMarkup: markup, parseMode: parseMode, disableWebPreview: webPreview, disableNtf: disableNtf, replyMessageID: makeReply)
      self.lastSentMessage = message
      return message
    }
    else { return nil }
  }
  
  // Sends a normal file.  A convenience method to keep core program code clean.
  public func send(file: SendType, markup: MarkupType? = nil, caption: String = "", reply: Bool = false, disableNtf: Bool = false) -> Message? {
    if currentMessage != nil {
      
      var makeReply = 0
      if reply == true {
        makeReply = currentMessage!.tgID
      }
      
      let message = bot.sendFile(chatID: chat.tgID, file: file, replyMarkup: markup, caption: caption, disableNtf: disableNtf, replyMessageID: makeReply)
      self.lastSentMessage = message
      return message
    }
    else { return nil }
  }
  
  // Uploads and sends a link.  The upload is also then stored on the file cache for re-use.
  public func send(link: FileLink, markup: MarkupType? = nil, callback: ReceiveUpload? = nil, caption: String = "", reply: Bool = false, disableNtf: Bool = false) {
    if currentMessage != nil {
      
      var makeReply = 0
      if reply == true {
        makeReply = currentMessage!.tgID
      }
      
      bot.uploadFile(link: link, callback: callback, chatID: chat.tgID, markup: markup, caption: caption, disableNtf: disableNtf, replyMessageID: makeReply)
    }
  }
  
  
  // Sends inline results based on a query request.
  public func send(inline: [InlineResult], queryID: String, cache: Int = 300, isPersonal: Bool = false, nextOffset: Int = 0, switchPM: String = "", switchPMParam: String = "") {
    bot.answerInlineQuery(inlineQueryID: queryID, results: inline, cacheTime: cache, isPersonal: isPersonal, nextOffset: nextOffset, switchPM: switchPM, switchPMParam: switchPMParam)
  }
  
  // Edits the text contents of a message.  A current message must be available.
  public func edit(messageText: String, markup: MarkupType? = nil, reply: Bool = false, parseMode: String = "", webPreview: Bool = false, disableNtf: Bool = false) {
    
    if lastSentMessage != nil {
      bot.editMessageText(chatID: chat.tgID, messageID: lastSentMessage!.tgID, text: messageText, replyMarkup: markup, parseMode: parseMode, disableWebPreview: disableNtf, replyMessageID: 0)
    }
  }
  
  // Edits the text contents of a message.  A current message must be available.
  public func edit(withMessage message: Message, text: String? = nil, markup: MarkupType? = nil, reply: Bool = false, replyID: Int = 0, parseMode: String = "", webPreview: Bool = false, disableNtf: Bool = false) {
    var newText = ""
    if text != nil { newText = text! }
    else { newText = message.text! }
    
    bot.editMessageText(chatID: message.chat.tgID, messageID: message.tgID, text: newText, replyMarkup: markup, parseMode: parseMode, disableWebPreview: disableNtf, replyMessageID: 0)
  }
  
  // Edits the markup of a message.
  public func edit(markup: MarkupType, reply: Bool = false) {
    if lastSentMessage != nil {
      bot.editMessageReplyMarkup(chatID: chat.tgID, messageID: lastSentMessage!.tgID, replyMarkup: markup, replyMessageID: 0)
    }
  }
  
  // Edits the caption of a file-type message.
  public func edit(caption: String, markup: MarkupType? = nil, reply: Bool = false) {
    if lastSentMessage != nil {
      bot.editMessageCaption(chatID: chat.tgID, messageID: lastSentMessage!.tgID, caption: caption, replyMarkup: markup, replyMessageID: 0)
    }
  }
  
  // Edits the caption of a file-type message with a specific sent message reference.
  public func edit(caption: String, message: Message, markup: MarkupType? = nil, reply: Bool = false) {
    bot.editMessageCaption(chatID: chat.tgID, messageID: message.tgID, caption: caption, replyMarkup: markup, replyMessageID: 0)
  }
  
  
  // Responds to a Callback Query through an alert
  public func answer(query: CallbackQuery, text: String, popup: Bool = false, gameURL: String = "") {
    bot.answerCallbackQuery(queryID: query.id, text: text, showAlert: popup, url: gameURL, cacheTime: 0)
  }
	
  
  // Bumps the flood limiter, and potentially blacklists or warns the user.
  func bumpFlood() {
    let limitHit = floodLimit.bump(globalTime: bot.globalTimer)
    if limitHit {
      
      // If we've reached the maximum maximum limit, add this chat ID to the blacklist
      if floodLimit.reachedLimit {
        bot.blacklistSession(session: self)
        return
      }
      
      // Otherwise if set, send the user a warning
      if bot.floodLimitWarning != nil {
        bot.floodLimitWarning!(self)
      }
    }
    
    // Sets the last interaction time to the current time
    lastInteractTime = bot.globalTimer
  }
  
  // Alters the maximum session time given.  DOESNT WORK YET PLZ NO.  Will also bump the session
  internal func changeSessionTime(_ time: Int) {
    self.maxSessionTime = time
    bot.bumpSession(self)
  }
}




