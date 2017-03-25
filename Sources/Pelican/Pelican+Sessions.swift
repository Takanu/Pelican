
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
  
  // Session settings
  internal var maxSessionTime: Int = 0 // What the current maximum for the session time is.  Set 0 for no timer.
  internal var lastInteractTime: Int = 0 // The last time the session was interacted with.
  var timedOut: Bool { return lastInteractTime <= bot.globalTimer - maxSessionTime }  // Checks whether or not this session has timed out.
  
  // Flood settings
  var floodLimit: FloodLimit
  
  // Response Settings
  var responseLimit: Int = 0 // The number of times a session will respond in a given timeframe.  Set as 0 for no limit.
  private var responseCount: Int = 0 // The number of times a response has been made in the timeframe.
  private var responseTime: Int = 0 // The time at which a response has currently been made
  
  // Current session state
  public var messageState: ((Message, Session) -> ())? // Used by the internal polling system to iterate over commands
  public var editedMessageState: ((Message, Session) -> ())? // Used by the internal polling system to iterate over commands
  public var channelState: ((Message, Session) -> ())? // Used by the internal polling system to iterate over commands
  public var editedChannelState: ((Message, Session) -> ())? // Used by the internal polling system to iterate over commands
  
  public var inlineQueryState: ((InlineQuery, Session) -> ())? // Used by the internal polling system to iterate over commands
  public var chosenInlineQueryState: ((ChosenInlineResult, Session) -> ())? // Used by the internal polling system to iterate over commands
  public var callbackQueryState: ((CallbackQuery, Session) -> ())? // Used by the internal polling system to iterate over commands
  
  public var sessionEndAction: ((Session) -> ())? // A command to be used when the session ends.
  var actionQueue: [TelegramBotSessionAction] = [] // Any queued actions that need to be monitored.
  
  // Stored requests
  public var currentMessage: Message?
  public var lastSentMessage: Message?
  var lastDialog: String = ""                     // A way to use the last given piece of dialog as a delay timer for the next.
  var plusTimer: Int = 0                          // A way to allow sequentially stated delays to naturally stack up.
  public var wordsPerMinute: Int = 190                   // Used as an implicit timer for a set of dialog actions.
  
  // Setup the session by passing a function that modifies itself with the required commands.
  public init(bot: Pelican, chat: Chat, data: NSCopying?, floodLimit: FloodLimit, setup: @escaping (Session) -> (), sessionEndAction: ((Session) -> ())? ) {
    self.bot = bot
    self.chat = chat
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
  //////////// ACTION TIMERS/DELAYS
  
  
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
  
  
  // Checks the current action queue.  Returns true if the action queue is empty after executing actions.
  func checkActions() -> Bool {
    
    if actionQueue.first != nil {
      while actionQueue.first!.time <= bot.globalTimer {
        let sessionAction = actionQueue.first!
        actionQueue.remove(at: 0)
        sessionAction.action(self)
        
        if actionQueue.count == 0 {
          return true
        }
      }
      return false
    }
    return true
  }
  
  // Im not sure about this, but whatever
  public func removeAction(name: String) {
    for (index, sessionAction) in actionQueue.enumerated() {
      if sessionAction.name == name {
        actionQueue.remove(at: index)
      }
    }
  }
  
  // Clears all actions (the bot process will clean it up next tick)
  public func clearActions() {
    actionQueue.removeAll()
  }
  
  // Ends the current session
  public func endSession(useAction: Bool = true) {
    if self.sessionEndAction != nil {
      self.sessionEndAction!(self)
    }
    
    bot.removeSession(session: self)
  }
  
  
}


// Defines a queued action for a specific session, to be run at a later date
class TelegramBotSessionAction {
  var name: String = ""           // Only used if the user may later want to find and remove the action before being played.
  var session: Session // The session to be affected
  var bot: Pelican
  var time: Int // The global time at which this should be executed
  var action: (Session) -> ()
  
  init(session: Session, bot: Pelican, delay: Int, action: @escaping (Session) -> (), name: String = "") {
    self.name = name
    self.session = session
    self.bot = bot
    self.time = bot.globalTimer + delay
    self.action = action
  }
  
  func execute() {
    action(session)
  }
  
  func changeTime(_ globalTime: Int) {
    time = globalTime
  }
  
  func delay(by: Int) {
    time += by
  }
}

// Used for creating groups of flood settings and keeping track of them.
public struct FloodLimit {
  private var floodLimit: Int = 0 // The number of messages it will accept before getting concerned.
  private var floodRange: Int = 0 // The time-frame that the flood limit and count applies to.
  private var floodCount: Int = 0 // The number of messages sent in the current window.
  private var floodRangeStart: Int = 0 // The starting time that the flood range applies to, in global time.
  
  var reachedLimit: Bool { return floodLimitHits >= breachLimit }
  private var floodLimitHits: Int = 0 // The number of times the limit has been hit
  private var breachLimit: Int = 0 // The number of times the limit can be hit before bad things happen.
  private var breachReset: Int = 0 // The time required for the breach limit to go down by one.
  private var breachResetStart: Int = 0 // The starting time that the reset applies to.
  
  // Initialises the flood limit type with a few settings
  public init(limit: Int, range: Int, breachLimit: Int, breachReset: Int) {
    self.floodLimit = limit
    self.floodRange = range
    self.breachLimit = breachLimit
    self.breachReset = breachReset
  }
  
  // Initialises it from another flood limit
  public init(clone: FloodLimit, withTime: Bool = false) {
    self.floodLimit = clone.floodLimit
    self.floodRange = clone.floodRange
    self.breachLimit = clone.breachLimit
    self.breachReset = clone.breachReset
    
    if withTime == true {
      self.floodCount = clone.floodCount
      self.floodRangeStart = clone.floodRangeStart
    }
    
  }
  
  // Increments the flood count, and returns whether or not this increment breached the flood limit.
  public mutating func bump(globalTime: Int) -> Bool {
    floodCount += 1
    
    // If we've hit the flood limit, increment the limit hits and set the flood and breach timers
    if floodCount >= floodLimit {
      floodLimitHits += 1
      floodCount = 0
      floodRangeStart = globalTime
      breachResetStart = globalTime
      return true
    }
    
    // If the flood range has been reached without flooding, reset the count
    if floodRangeStart <= globalTime - floodRange {
      floodCount = 0
      floodRangeStart = globalTime
    }
    
    // If the breach reset has been hit, reduce the breach hits by one to cool off the "alert" level.
    if breachResetStart <= globalTime - breachReset {
      if floodLimitHits > 0 { floodLimitHits -= 0 }
      floodRangeStart = globalTime
    }
    
    return false
  }
}

