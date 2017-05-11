
import Dispatch     // Linux thing.
import Foundation
import Vapor
import HTTP
import FormData
import Multipart

protocol TelegramParameter: NodeConvertible, JSONConvertible {
  func getQueryParameter() -> String
}


// The Dispatch queue for getting updates and serving them to sessions.
private class UpdateQueue {
  private let queue = DispatchQueue(label: "TG-Updates",
                                    qos: .userInteractive,
                                    target: nil)
  
  private let interval: TimeInterval
  private let execute: () -> Void
  private var operation: DispatchWorkItem?
  
  init(interval: TimeInterval, execute: @escaping () -> Void) {
    self.interval = interval
    self.execute = execute
  }
  
  func start() {
    let operation = DispatchWorkItem(qos: .userInteractive, flags: .enforceQoS) { [weak self] in
      
      defer { self?.start() }
      self?.execute()
    }
    self.operation = operation
    queue.asyncAfter(deadline: .now() + interval, execute: operation)
  }
  
  func stop() {
    operation?.cancel()
  }
}

// Defined the kind of action you wish a chat action to specify.
public enum ChatAction: String {
  case typing = "typing"
  case photo = "upload_photo"
  case uploadVideo = "upload_video"
  case recordVideo = "record_video"
  case uploadAudio = "upload_audio"
  case recordAudio = "record_audio"
  case document = "upload_document"
  case location = "find_location"
}

enum TGBotError: String, Error {
  case KeyMissing = "The API key hasn't been provided.  Please provide a \"token\" for Config/pelican.json, containing your bot token."
  case EntryMissing = "Pelican hasn't been given an session setup closure.  Please provide one using the type sessionSetupAction."
}

// Errors related to request fetching
enum TGReqError: String, Error {
  case NoResponse = "The request received no response."
  case UnknownError = "Something happened, and i'm not sure what!"
  case BadResponse = "Telegram responded with \"NOT OKAY\" so we're going to trust that it means business."
  case ResponseNotExtracted = "The request could not be extracted."
}

// Errors related to update processing.  Might merge the two?
enum TGUpdateError: String, Error {
  case BadUpdate = "The message received from Telegram was malformed or unable to be processed by this bot."
}

public enum TGUpdateType: String {
  case message, edited_message, channel_post, edited_channel_post, inline_query, chosen_inline_result, callback_query
}

// Used to switch between node build types in
public enum TGContext: Context {
  case response
  case db
}

// Holds the received updates in a set of sorted arrays.
public struct TelegramUpdateSet {
  var messages: [Message] = []
  var editedMessages: [Message] = []
  var channelPosts: [Message] = []
  var editedChannelPosts: [Message] = []
  var inlineQueries: [InlineQuery] = []
  var inlineResults: [ChosenInlineResult] = []
  var callbackQueries: [CallbackQuery] = []
  
  func printDebug() {
    print(messages, editedMessages, channelPosts, editedChannelPosts, inlineQueries, inlineResults, callbackQueries)
  }
}

public final class Pelican: Vapor.Provider {
  public let message: String = "Rawr."
  public var provided: Providable { return Providable() }
  
  var drop: Droplet
  var cache: CacheManager               // A class for managing previously uploaded files and file links.
  var apiKey: String              // The API key assigned to your bot.
  var apiURL: String              // The combination of the API request URL and your key
  private var customData: NSCopying?      // Defines an object to be used for custom data.
  
  // Variables used for long polling
  public var offset: Int = 0
  public var limit: Int = 100
  public var timeout: Int = 0
  public var allowedUpdates: [TGUpdateType] = []     // Leave empty if all are allowed, otherwise specify.
  public var ignoreInitialUpdates: Bool = true       // If the bot has just started, it will ignore all received messages since it has been offline.
  private var started: Bool = false
  public var hasStarted: Bool { return started }
  
  // Timers
  fileprivate var updateQueue: UpdateQueue?
  var uploadQueue: DispatchQueue
  var pollInterval: Int = 0
  var globalTimer: Int = 0        // Used for executing scheduled events.
  public var getTime: Int { return globalTimer }
  
  // Connection settings
  public var maxRequestAttempts: Int = 0 // The maximum number of times the bot will attempt to get a response before it logs an error.
  
  // Sessions
  private var sessions: [Int:Session] = [:]        // The currently active sessions, ordered by how recently it was interacted with (longer = smaller index).
  private var sessionActivity: [Session] = []      // Records when a session was last used, to keep track of when sessions need to be closed.
  private var sessionsEvents: [Int:Session] = [:]  // Used for keeping track of sessions that have events.
  
  public var maxSessions: Int = 0                            // The maximum number of sessions the bot will support before it stops people from using it.  Leave at 0 for no limit.
  public var maxSessionsAction: ((Pelican, Chat) -> ())? // Define an action if desired to perform when someone tries this way
  public var defaultMaxSessionTime: Int = 0                  // The maximum amount of time in seconds that a session should last for.
  
  public var sessionSetupAction: ((Session) -> ())?  // What happens when the session begins,
  public var sessionEndAction: ((Session) -> ())?  // What should be run when the session ends.  Could be nothing!
  
  // Flood Limit
  public var floodLimit: FloodLimit = FloodLimit(limit: 250, range: 300, breachLimit: 2, breachReset: 500)  // Settings that define flood limit restrictions for each session
  public var floodLimitWarning: ((Session) -> ())? // An optional warning to send to people the first time they hit the flood warning.
  
  // Response Settings
  public var responseLimit: Int = 0  // The number of times a session will respond to a message in a given poll interval before ignoring them.  Set as 0 for no limit.
  public var restrictUsers: Bool = false // Restricts the users that can use a session to only those specified in the session list if true.
  
  // Blacklist
  public lazy var mod = Moderator()
  public var whitelistWarningAction: ((Pelican, Chat) -> ())? // Define an action if someone not on the whitelist messages it.
  public var blacklistPrepareAction: ((Pelican, Chat) -> ())? // Define an action if someone enters the blacklist.

  
  
  
  public init(config: Config) throws {
    guard let token = config["pelican", "token"]?.string else {
      throw TGBotError.KeyMissing
    }
    
    self.cache = CacheManager()
    self.apiKey = token
    self.apiURL = "https://api.telegram.org/bot" + apiKey
    
    self.uploadQueue = DispatchQueue(label: "TG-Upload",
                                     qos: .background,
                                     target: nil)
    self.drop = Droplet()
  }
  
  
  public func afterInit(_ drop: Droplet) {
    self.drop = drop
    try! cache.setBundlePath(drop.workDir + "Public/")
  }
  
  public func beforeRun(_ drop: Droplet) {
    if self.sessionSetupAction == nil {
      drop.console.warning(TGBotError.EntryMissing.rawValue, newLine: true)
    }
    
    if ignoreInitialUpdates == true {
      _ = self.getUpdateSets()
    }
    
    if allowedUpdates.count == 0 {
      for type in iterateEnum(TGUpdateType.self) {
        allowedUpdates.append(type)
      }
    }
    
    started = true
    updateQueue!.start()
    //Jobs.add(interval: .seconds(Double(pollInterval))) {
    //    self.filterUpdates()
    //}
  }
  
  public func boot(_: Droplet) {}
  
  
  
  public func setCustomData(_ data: NSCopying) {
    self.customData = data.copy(with: nil) as? NSCopying
  }
  
  public func setPoll(interval: Int) {
    updateQueue = UpdateQueue(interval: TimeInterval(interval)) {
      self.filterUpdates()
    }
    
    pollInterval = interval
  }
  
  internal func makeUpdateQuery() -> [String:CustomStringConvertible] {
    var keys: [String:CustomStringConvertible] = [
      "offset": offset,
      "limit": limit,
      "timeout": timeout]
    
    var filteredUpdates: [String] = []
    for item in allowedUpdates {
      if !filteredUpdates.contains(item.rawValue) {
        filteredUpdates.append(item.rawValue)
      }
    }
    
    keys["allowed_updates"] = filteredUpdates
    return keys
  }
  
  // Processes and organises all updates into sets of tuples for easy filtering.
  public func getUpdateSets() -> (TelegramUpdateSet)? {
    let query = makeUpdateQuery()
    
    guard let response = try? drop.client.get(apiURL + "/getUpdates", query: query) else {
      drop.console.error(TGReqError.NoResponse.rawValue, newLine: true)
      return nil
    }
    
    // Get the basic result data
    let result: Array = response.data["result"]?.array ?? []
    let messageCount = result.count
    
    // Make the collection types
    var updateSet = TelegramUpdateSet()
    
    // Iterate through the collected messages
    for i in 0..<messageCount {
      let update_id = response.data["result", i, "update_id"]?.int ?? -1
      
      
      // This is just a plain old message
      if allowedUpdates.contains(TGUpdateType.message) {
        if (response.data["result", i, "message"]) != nil {
          guard let messageNode = response.json?.node["result", i, "message"]!.node else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
          guard let message = try? Message(node: messageNode, in: TGContext.response) else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
          updateSet.messages.append(message)
        }
      }
      
      // This is if a message was edited
      if allowedUpdates.contains(TGUpdateType.edited_message) {
        if (response.data["result", i, "edited_message"]) != nil {
          guard let messageNode = response.json?.node["result", i, "edited_message"]!.node else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
          guard let message = try? Message(node: messageNode, in: TGContext.response) else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
          updateSet.editedMessages.append(message)
        }
      }
      
      // This is for a channel post
      if allowedUpdates.contains(TGUpdateType.channel_post) {
        if (response.data["result", i, "channel_post"]) != nil {
          guard let messageNode = response.json?.node["result", i, "channel_post"]!.node else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
          guard let message = try? Message(node: messageNode, in: TGContext.response) else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
          updateSet.channelPosts.append(message)
        }
      }
      
      // This is for an edited channel post
      if allowedUpdates.contains(TGUpdateType.edited_channel_post) {
        if (response.data["result", i, "edited_channel_post"]) != nil {
          guard let messageNode = response.json?.node["result", i, "edited_channel_post"]!.node else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
          guard let message = try? Message(node: messageNode, in: TGContext.response) else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
          updateSet.editedChannelPosts.append(message)
        }
      }
      
      // COME BACK TO THESE LATER
      // This type is for when someone tries to search something in the message box for this bot
      if allowedUpdates.contains(TGUpdateType.inline_query) {
        if (response.data["result", i, "inline_query"]) != nil {
          guard let messageNode = response.json?.node["result", i, "inline_query"]!.node else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
          guard let message = try? InlineQuery(node: messageNode, in: TGContext.response) else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
          updateSet.inlineQueries.append(message)
        }
      }
      
      // This type is for when someone has selected an search result from the inline query
      if allowedUpdates.contains(TGUpdateType.chosen_inline_result) {
        if (response.data["result", i, "chosen_inline_result"]) != nil {
          guard let messageNode = response.json?.node["result", i, "chosen_inline_result"]!.node else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
          guard let message = try? ChosenInlineResult(node: messageNode, in: TGContext.response) else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
          updateSet.inlineResults.append(message)
        }
      }
      
      // I think this is related to message buttons?
      if allowedUpdates.contains(TGUpdateType.callback_query) {
        if (response.data["result", i, "callback_query"]) != nil {
          guard let messageNode = response.json?.node["result", i, "callback_query"]!.node else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
          guard let message = try? CallbackQuery(node: messageNode, in: TGContext.response) else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
          updateSet.callbackQueries.append(message)
        }
      }
      
      offset = update_id + 1
    }
    
    return (updateSet)
  }
  
  // Used by the in-built long polling solution to compare results to commands.
  internal func filterUpdates() {
    //print("START")
    guard let updates = getUpdateSets() else {
      return
    }
    
    updates.printDebug()
    
    // Check the global timer for any scheduled events
    globalTimer += pollInterval
    checkSessionActivity()
    checkSessionEvents()
    
    // Filter updates
    for msg in updates.messages {
      if sessions.index(forKey: msg.chat.tgID) != nil {
        let session = sessions[msg.chat.tgID]!
        session.filterUpdate(message: msg)
        bumpSession(session)
      }
        
        // If nothing matched, attempt to make a new session and send the message to it.
      else {
        let session = addSession(chat: msg.chat, user: msg.from)
        if session != nil {
          session?.filterUpdate(message: msg)
          bumpSession(session!)
        }
      }
    }
    
    // Filter Inline Queries
    for query in updates.inlineQueries {
      for session in sessions {
        if session.value.hasUser(query.from) == true || restrictUsers == false {
          session.value.filterInlineQuery(query: query)
          bumpSession(session.value)
        }
      }
    }
    
    // Filter Inline Selection Queries
    for query in updates.inlineResults {
      for session in sessions {
        if session.value.hasUser(query.from) == true || restrictUsers == false {
          session.value.filterInlineResult(query: query)
          bumpSession(session.value)
        }
      }
    }
    
    // Filter Callback Queries
    for query in updates.callbackQueries {
      if query.message != nil {
        if sessions[Int(query.message!.chat.tgID)] != nil {
          let session = sessions[Int(query.message!.chat.tgID)]
          session?.filterQuery(query: query)
          bumpSession(session!)
        }
      }
    }
    
    //print("FINISH")
  }
  
  /* Adds a session to the Telegram Bot.  A session represents a single chat or instance of activity between a person and the bot. */
  func addSession(chat: Chat, user: User?) -> Session? {
    print(">>>>> ADDING NEW SESSION <<<<<")
    print(String(chat.tgID) + " - " + (chat.title ?? chat.firstName!))
    
    
    // If the chat requesting it isn't authorised, return nothing
    if mod.authorise(chat: chat) == false {
      print("Chat not authorized, returning...")
      return nil
    }
    
    // If the user requesting it isn't authorised, return nothing...
    if user != nil {
      if mod.authorise(user: user!) == false {
        print("User not authorized, returning...")
        return nil
      }
    }
    
    
    // If we've reached the maximum number of allowed sessions, send them a message if available.
    if sessions.count >= maxSessions && maxSessions != 0 {
      print("Session count reached.  Deferring.")
      if maxSessionsAction != nil { maxSessionsAction!(self, chat) }
      return nil
    }
    
    
    // If we're still here, add them.
    if sessionSetupAction == nil { print(TGBotError.EntryMissing.rawValue) ; return nil }
    let session = Session(bot: self, chat:chat, data: customData, floodLimit: floodLimit, setup: self.sessionSetupAction!, sessionEndAction: self.sessionEndAction)
    session.postInit()
    session.responseLimit = self.responseLimit
    
    sessions[chat.tgID] = session
    sessionActivity.append(session)
    
    print("Session added.")
    print("Current Active Sessions: ")
    print(sessions)
    
    return session
  }
  
  // Bumps a session up the activity queue
  internal func bumpSession(_ session: Session) {
    
    // Find the session to be bumped up
    for (index, value) in sessionActivity.enumerated() {
      
      // If found, pull it from the stack and add it to the end.
      if value.chat.id == session.chat.id {
        sessionActivity.remove(at: index)
        sessionActivity.append(session)
      }
    }
  }
  
  // Checks session activity, and whether any sessions need to be removed.
  internal func checkSessionActivity() {
    // If no max session time is set (and it really should be) , ignore checks.
    if defaultMaxSessionTime == 0 { return }
    
    // While the first session is timed out, end it and remove it from all stacks.
    while sessionActivity.first?.timedOut == true {
      
      let session = sessionActivity.first!
      print("Session Time Out - ", (session.chat.title ?? session.chat.firstName!))
      print(String(session.chat.tgID) + " - " + (session.chat.title ?? session.chat.firstName!))
      
      if session.sessionEndAction != nil {
        session.sessionEndAction!(session)
      }
      
      // Remove the session from all arrays
      sessions.removeValue(forKey: session.chat.tgID)
      sessionsEvents.removeValue(forKey: session.chat.tgID)
      sessionActivity.remove(at: 0)
      
      print("Session Removed.")
      print("Current Active Sessions: ")
      print(sessions)
    }
  }
  
  
  // Removes a specified session.  Will not call the session endSessionAction, assumes it is being called from the session itself.
  func removeSession(session: Session) {
    print("REMOVING SESSION - ", (session.chat.title ?? session.chat.firstName!))
    sessions.removeValue(forKey: session.chat.tgID)
    sessionsEvents.removeValue(forKey: session.chat.tgID)
    
    for (index, value) in sessionActivity.enumerated() {
      if value.chat.tgID == session.chat.tgID {
        sessionActivity.remove(at: index)
      }
    }
  }
  
  
  // chatBlacklists the session!
  func blacklistSession(session: Session) {
    
    // If we have a user in the session, blacklist them
    if session.primaryUser != nil {
      mod.addToBlacklist(user: session.primaryUser!)
      removeSession(session: session)
      print("User Blacklisted - ", session.primaryUser!.tgID, " - ", session.primaryUser!.firstName)
    }
      
      // If not, blacklist the chat (there should always be a user, correct this bad fucking code)
    else {
      mod.addToBlacklist(chat: session.chat)
      removeSession(session: session)
      print("Chat Blacklisted - ", session.chat.tgID, " - ", session.chat.firstName!)
    }
  }
  
  
  // Adds a session to the list of sessions that have active events
  internal func addSessionEvent(session: Session) {
    if sessionsEvents[session.chat.tgID] == nil {
      print("NEW SESSION EVENT ADDED")
      sessionsEvents[session.chat.tgID] = session
      print(sessionsEvents)
    }
  }
  
  
  // Checks all the currently active session events.
  internal func checkSessionEvents() {
    for session in sessionsEvents {
      
      let result = session.value.checkActions()
      if result == true {
        print("SESSION EVENTS COMPLETE, REMOVING...")
        sessionsEvents.removeValue(forKey: session.key)
        print(sessionsEvents)
      }
    }
  }
}
