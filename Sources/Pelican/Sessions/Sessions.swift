
import Foundation
import Vapor

// Holds the information for a bot session, when someone is immediately interacting with the bot
// Ignore this if you want?  What am i, a doctor?
public class Session {
  public var id: Node?           // Database ID
  public var bot: Pelican        // The bot associated with this session
  public var chat: Chat          // The chat ID associated with the session.
  public var primaryUser : User? // The primary user associated with this session, not applicable for channels or potentially other things.
  public var users: [User] = []  // Other users associated with this session.  The primary user is likely in this list.
  public var data: NSCopying?    // User-defined data chunk.
  
  public var prompts: PromptController    // Container for automating markup options and responses.
  var floodLimit: FloodLimit     // External flood tracking system.
  
  // Session settings
  var maxSessionTime: Int = 0 // What the current maximum for the session time is.  Set 0 for no timer.
  internal var lastInteractTime: Int = 0 // The last time the session was interacted with.
  var timedOut: Bool { return lastInteractTime <= bot.globalTimer - maxSessionTime }  // Checks whether or not this session has timed out.
  
  
  
  // Response Settings
  var responseLimit: Int = 0 // The number of times a session will respond in a given timeframe.  Set as 0 for no limit.
  private var responseCount: Int = 0 // The number of times a response has been made in the timeframe.
  private var responseTime: Int = 0 // The time at which the last response has been made (in bot time).
  
  
  // Current session state
  public var messageState: ((Message, Session) -> ())?
  public var editedMessageState: ((Message, Session) -> ())?
  public var channelState: ((Message, Session) -> ())?
  public var editedChannelState: ((Message, Session) -> ())?
  
  public var inlineQueryState: ((InlineQuery, Session) -> ())?
  public var chosenInlineQueryState: ((ChosenInlineResult, Session) -> ())?
  public var callbackQueryState: ((CallbackQuery, Session) -> ())?
  
  public var sessionEndAction: ((Session) -> ())? // A command to be used when the session ends.
  var actionQueue: [TelegramBotSessionAction] = [] // Any queued actions that need to be monitored.
  
  
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
  
  // Functions for managing what users are associated to this session.
  public func hasUser(_ user: User) -> Bool {
    if users.count == 0 { return false }
    if users.contains(where: { $0.tgID == user.tgID } ) == true { return true }
    return false
  }
  
  public func addUser(_ user: User) {
    users.append(user)
  }
  
  
  // Preparation conforming methods, for creating and deleting a database.
  public static func prepare(_ database: Database) throws {
    try database.create("users") { users in
      users.id()
    }
  }
  
  public static func revert(_ database: Database) throws {
    try database.delete("users")
  }
  
  // Clears all states.
  public func clearStates() {
    self.messageState = nil
    self.editedMessageState = nil
    self.channelState = nil
    self.editedChannelState = nil
    
    self.inlineQueryState = nil
    self.chosenInlineQueryState = nil
    self.callbackQueryState = nil
    
    print(self.messageState as Any)
  }
  
  // Receives a message from the TelegramBot to check whether in the current state anything can be done with it
  func filterUpdate(message: Message) {
    
    // Set the current message
    currentMessage = message
    
    // If the message state has a function to perform, try to perform it.
    if (self.messageState != nil) {
      
      // If the response time doesn't match, we're responding to a new batch of messages, so reset it.
      if bot.globalTimer != responseTime {
        responseTime = bot.globalTimer
        responseCount = 0
      }
      
      // If we haven't yet reached our response limit, call the state.
      if responseCount < responseLimit && responseLimit != 0 {
        self.messageState!(message, self)
      }
      
      responseCount += 1
      
    }
    
    // Check the flood status
    bumpFlood()
  }
  
  func filterInlineQuery(query: InlineQuery) {
    
    // Call the callback query if we have one.
    if (self.inlineQueryState != nil) {
      self.inlineQueryState!(query, self)
    }
    
    // Check the flood status
    bumpFlood()
  }
  
  func filterInlineResult(query: ChosenInlineResult) {
    
    // Call the callback query if we have one.
    if (self.chosenInlineQueryState != nil) {
      self.chosenInlineQueryState!(query, self)
    }
    
    // Check the flood status
    bumpFlood()
  }
  
  func filterQuery(query: CallbackQuery) {
    
    // Call the callback query if we have one.
    if (self.callbackQueryState != nil) {
      self.callbackQueryState!(query, self)
    }
    
    else if prompts.count != 0 {
      prompts.filterQuery(query, session: self)
    }
    
    // Check the flood status
    bumpFlood()
  }
  
  ////////////////////////////////////////////////////
  //////////// NORMAL SEND REQUESTS
  
  
  // Sends a normal message.  A convenience method to keep core program code clean.
  public func send(message: String, markup: MarkupType? = nil, reply: Bool = false, parseMode: String = "", webPreview: Bool = false, disableNtf: Bool = false) -> Message? {
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
  public func send(link: FileUpload, markup: MarkupType? = nil, caption: String = "", reply: Bool = false, disableNtf: Bool = false) {
    if currentMessage != nil {
      
      var makeReply = 0
      if reply == true {
        makeReply = currentMessage!.tgID
      }
      
      bot.uploadFile(link: link, chatID: chat.tgID, markup: markup, caption: caption, disableNtf: disableNtf, replyMessageID: makeReply)
    }
  }
  
  
  // Sends inline results based on a query request.
  public func send(inline: [InlineResult], queryID: String, cache: Int = 300, isPersonal: Bool = false, nextOffset: Int = 0, switchPM: String = "", switchPMParam: String = "") {
    bot.answerInlineQuery(inlineQueryID: queryID, results: inline, cacheTime: cache, isPersonal: isPersonal, nextOffset: nextOffset, switchPM: switchPM, switchPMParam: switchPMParam)
  }
  
  // Edits the text contents of a message.  A current message must be available.
  public func edit(message: String, markup: MarkupType? = nil, reply: Bool = false, parseMode: String = "", webPreview: Bool = false, disableNtf: Bool = false) {
    
    if lastSentMessage != nil {
      bot.editMessageText(chatID: chat.tgID, messageID: lastSentMessage!.tgID, text: message, replyMarkup: markup, parseMode: parseMode, disableWebPreview: disableNtf, replyMessageID: 0)
    }
  }
  
  // Edits the inline contents of a message, using a provides message object.
  public func edit(message: Message, markup: MarkupType? = nil) {
    bot.editMessageReplyMarkup(chatID: message.chat.tgID, messageID: message.tgID, replyMarkup: markup, replyMessageID: 0)
  }
  
  // Edits the markup of a message.
  public func edit(markup: MarkupType, reply: Bool = false) {
    if lastSentMessage != nil {
      bot.editMessageReplyMarkup(chatID: chat.tgID, messageID: lastSentMessage!.tgID, replyMarkup: markup, replyMessageID: 0)
    }
  }
  
  // Responds to a Callback Query through an alert
  public func answer(query: CallbackQuery, text: String, popup: Bool = false, gameURL: String = "") {
    bot.answerCallbackQuery(queryID: query.id, text: text, showAlert: popup, url: gameURL, cacheTime: 0)
  }
  
  
  ////////////////////////////////////////////////////
  //////////// METHOD DELAYS
  
  
  // Delays execution of an action by the specified time
  public func delay(by time: Int, stack: Bool, name: String = "", action: @escaping (Session) -> ()) {
    
    // Calculate what kind of delay we're using
    var delay = 0
    if stack == true {
      if lastDialog != "" {
        let wordCount = lastDialog.components(separatedBy: NSCharacterSet.whitespaces).count
        let readTime = Int(ceil(Float(wordCount) / Float(wordsPerMinute / 60)))
        delay = Int(readTime) + time + plusTimer
        plusTimer = delay
        //lastDialog = ""
      }
        
      else {
        delay = plusTimer + time
        plusTimer = delay
      }
    }
    else { delay = time }
    
    print("New Delay - \(delay)")
    
    let action = TelegramBotSessionAction(session: self, bot: bot, delay: delay, action: action, name: name)
    
    // Enumerate through the queue to find a position to insert it, to keep the list ordered.
    for (key, value) in actionQueue.enumerated() {
      if value.time > action.time {
        let insert = key
        actionQueue.insert(action, at: insert)
        bot.addSessionEvent(session: self)
        return
      }
    }
    
    // If it wasn't appended before, the criteria wasn't met.  Add here.
    actionQueue.append(action)
    bot.addSessionEvent(session: self)
  }
  
  // A shorthand function for sending a single message in a delayed fashion, through the action system.  Looks a lot neater :D
  public func delaySend(by: Int, message: String, markup: MarkupType? = nil, reply: Bool = false, parseMode: String = "", webPreview: Bool = false, disableNtf: Bool = false) {
    self.delay(by: by, stack: false, action: { session in
      _ = session.send(message: message, markup: markup, reply: reply, parseMode: parseMode, webPreview: webPreview, disableNtf: disableNtf)
    })
  }
  
  // A shorthand function for sending a single message in a delayed fashion with an additional stack option that adds the delay
  // to the top of the stack using a timer, instead of measuring the delay from the moment the request is made.
  public func delaySend(by: Int, stack: Bool, message: String, markup: MarkupType? = nil, reply: Bool = false, parseMode: String = "", webPreview: Bool = false, disableNtf: Bool = false) {
    
    self.delay(by: by, stack: stack, action: { session in
      _ = session.send(message: message, markup: markup, reply: reply, parseMode: parseMode, webPreview: webPreview, disableNtf: disableNtf)
    })
  }
  
  // Properly calculates a delay to send this dialog based on a pause and the previous dialog length.
  public func delayDialog(pause: Int = 0, dialog: String, markup: MarkupType? = nil, reply: Bool = false, parseMode: String = "", webPreview: Bool = false, disableNtf: Bool = false) {
    
    // Work out the average reading time, this uses it's own stack
    let wordCount = lastDialog.components(separatedBy: NSCharacterSet.whitespaces).count
    let readTime = Int(ceil(Float(wordCount) / Float(wordsPerMinute / 60)))
    let by = Int(readTime) + pause + plusTimer
    plusTimer = by
    lastDialog = dialog
    
    print("New Dialog Delay - \(plusTimer)")
    
    self.delay(by: by, stack: false, action: { session in
      _ = session.send(message: dialog, markup: markup, reply: reply, parseMode: parseMode, webPreview: webPreview, disableNtf: disableNtf)
    })
  }
  
  // Edits the text contents of a message in a delayed fashion.  A last sent message must be available.
  public func delayEdit(by: Int, message: String, markup: MarkupType? = nil, reply: Bool = false, parseMode: String = "", webPreview: Bool = false, disableNtf: Bool = false) {
    
    if lastSentMessage != nil {
      self.delay(by: by, stack: false, action: { session in
        self.bot.editMessageText(chatID: self.chat.tgID, messageID: self.lastSentMessage!.tgID, text: message, replyMarkup: markup, parseMode: parseMode, disableWebPreview: disableNtf, replyMessageID: 0)
      })
    }
  }
  
  // Edits the text contents of a message in a delayed fashion, using a message object.
  public func delayEdit(by: Int, message: Message, markup: MarkupType? = nil) {
    self.delay(by: by, stack: false, action: { session in
      self.bot.editMessageReplyMarkup(chatID: message.chat.tgID, messageID: message.tgID, replyMarkup: markup, replyMessageID: 0)
    })
  }
  
  // A shorthand function for editing a single message in a delayed fashion with an additional stack option that adds the delay
  // to the top of the stack using a timer, instead of measuring the delay from the moment the request is made.
  public func delayEdit(by: Int, stack: Bool, message: Message, markup: MarkupType? = nil) {
    
    self.delay(by: by, stack: stack, action: { session in
      self.bot.editMessageReplyMarkup(chatID: message.chat.tgID, messageID: message.tgID, replyMarkup: markup, replyMessageID: 0)
    })
  }
  
  
  // Resets the assistive timers
  public func resetTimerAssists() {
    self.plusTimer = 0
    self.lastDialog = ""
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




