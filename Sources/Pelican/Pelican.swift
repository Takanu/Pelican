
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

private enum TGBotError: String, Error {
    case KeyMissing = "The API key hasn't been provided.  Please provide a \"token\" for Config/pelican.json, containing your bot token."
    case EntryMissing = "Pelican hasn't been given an session setup closure.  Please provide one using the type sessionSetupAction."
}

// Errors related to request fetching
private enum TGReqError: String, Error {
    case NoResponse = "The request received no response."
    case UnknownError = "Something happened, and i'm not sure what!"
    case BadResponse = "Telegram responded with \"NOT OKAY\" so we're going to trust that it means business."
    case ResponseNotExtracted = "The request could not be extracted."
}

// Errors related to update processing.  Might merge the two?
private enum TGUpdateError: String, Error {
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
    var cache: TGCacheManager               // A class for managing previously uploaded files and file links.
    private var apiKey: String              // The API key assigned to your bot.
    private var apiURL: String              // The combination of the API request URL and your key
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
    
    // Connection settings
    public var maxRequestAttempts: Int = 0 // The maximum number of times the bot will attempt to get a response before it logs an error.
    
    // Sessions
    private var sessions: [Int:TelegramBotSession] = [:]        // The currently active sessions, ordered by how recently it was interacted with (longer = smaller index).
    private var sessionActivity: [TelegramBotSession] = []      // Records when a session was last used, to keep track of when sessions need to be closed.
    private var sessionsEvents: [Int:TelegramBotSession] = [:]  // Used for keeping track of sessions that have events.
    
    public var maxSessions: Int = 0                            // The maximum number of sessions the bot will support before it stops people from using it.  Leave at 0 for no limit.
    public var maxSessionsAction: ((Pelican, Chat) -> ())? // Define an action if desired to perform when someone tries this way
    public var defaultMaxSessionTime: Int = 0                  // The maximum amount of time in seconds that a session should last for.
    
    public var sessionSetupAction: ((TelegramBotSession) -> ())?  // What happens when the session begins,
    public var sessionEndAction: ((TelegramBotSession) -> ())?  // What should be run when the session ends.  Could be nothing!
    
    // Flood Limit
    public var floodLimit: FloodLimit = FloodLimit(limit: 250, range: 300, breachLimit: 2, breachReset: 500)  // Settings that define flood limit restrictions for each session
    public var floodLimitWarning: ((TelegramBotSession) -> ())? // An optional warning to send to people the first time they hit the flood warning.
    
    // Response Settings
    public var responseLimit: Int = 0  // The number of times a session will respond to a message in a given poll interval before ignoring them.  Set as 0 for no limit.
    public var restrictUsers: Bool = false // Restricts the users that can use a session to only those specified in the session list if true.
    
    // Blacklist
    public var userBlacklist: [User] = []
    public var userWhitelist: [User] = []
    public var whitelistWarningAction: ((Pelican, Chat) -> ())? // Define an action if someone not on the whitelist messages it.
    public var blacklistPrepareAction: ((Pelican, Chat) -> ())? // Define an action if someone enters the blacklist.
    public var chatWhitelist: [Chat] = [] // Used for testing or small betas, where you'd only like the beta to occur for a specific chat or chats.
    public var chatBlacklist: [Chat] = [] // Used to block a chat if no user data is available.
    
    
    
    
    public init(config: Config) throws {
        guard let token = config["pelican", "token"]?.string else {
            throw TGBotError.KeyMissing
        }
        
        self.cache = TGCacheManager()
        self.apiKey = token
        self.apiURL = "https://api.telegram.org/bot" + apiKey
        
        self.uploadQueue = DispatchQueue(label: "TG-Upload",
                                         qos: .background,
                                         target: nil)
        self.drop = Droplet()
    }
    
    
    public func afterInit(_ drop: Droplet) {
        self.drop = drop
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
        print("START")
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

        print("FINISH")
    }
    
    /* Adds a session to the Telegram Bot.  A session represents a single chat or instance of activity between a person and the bot. */
    func addSession(chat: Chat, user: User?) -> TelegramBotSession? {
        print(">>>>> ADDING NEW SESSION <<<<<")
        print(String(chat.tgID) + " - " + (chat.title ?? chat.firstName!))
        
        
        // If they're not on the whitelist they should be blown off
        if user != nil {
            if userWhitelist.count > 0 {
                if userWhitelist.contains(where: { $0.tgID == user!.tgID } ) == false {
                    print("User not in the whitelist, responding...")
                    if whitelistWarningAction != nil {
                        whitelistWarningAction!(self, chat)
                    }
                    return nil
                }
            }
            
            // If they're in the Blacklist, doubly so.
            if userBlacklist.count > 0 {
                if userBlacklist.contains(where: { $0.tgID == user!.tgID } ) {
                    print("User in the chatBlacklist, ignore!")
                    return nil
                }
            }
        }
        
        // If there's a whitelist chat and the chat isn't in it, also blow them off
        if chatWhitelist.contains(where: { $0.tgID == chat.tgID } ) == false {
            print("Chat not in the whitelist, responding...")
            if whitelistWarningAction != nil {
                whitelistWarningAction!(self, chat)
            }
            return nil
        }
        
        // If there's a whitelist chat and the chat isn't in it, also blow them off
        if chatBlacklist.contains(where: { $0.tgID == chat.tgID } ) {
            print("Chat in the Blacklist, ignore!")
            return nil
        }
            
            
    
        // If we've reached the maximum number of allowed sessions, send them a message if available.
        if sessions.count >= maxSessions && maxSessions != 0 {
            print("Session count reached.  Deferring.")
            if maxSessionsAction != nil { maxSessionsAction!(self, chat) }
            return nil
        }
            
        
        // If we're still here, add them.
        if sessionSetupAction == nil { print(TGBotError.EntryMissing.rawValue) ; return nil }
        let session = TelegramBotSession(bot: self, chat:chat, data: customData, floodLimit: floodLimit, setup: self.sessionSetupAction!, sessionEndAction: self.sessionEndAction)
        session.responseLimit = self.responseLimit
            
        sessions[chat.tgID] = session
        sessionActivity.append(session)
        
        print("Session added.")
        print("Current Active Sessions: ")
        print(sessions)
            
        return session
    }
    
    // Bumps a session up the activity queue
    internal func bumpSession(_ session: TelegramBotSession) {
        
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
    func removeSession(session: TelegramBotSession) {
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
    func blacklistSession(session: TelegramBotSession) {
        
        // If we have a user in the session, blacklist them
        if session.primaryUser != nil {
            self.userBlacklist.append(session.primaryUser!)
            removeSession(session: session)
            print("User Blacklisted - ", session.primaryUser!.tgID, " - ", session.primaryUser!.firstName)
        }
        
            // If not, blacklist the chat (there should always be a user, correct this bad fucking code)
        else {
            self.chatBlacklist.append(session.chat)
            removeSession(session: session)
            print("Chat Blacklisted - ", session.chat.tgID, " - ", session.chat.firstName!)
        }
    }
    
    // Adds a session to the list of sessions that have active events
    internal func addSessionEvent(session: TelegramBotSession) {
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
    
    
    //////////////////////////////////////////////////////////////////////////////////
    //// TELEGRAM CORE METHOD IMPLEMENTATIONS
    
    // A simple function used to test the authentication key
    public func getMe() -> User? {
        // Attempt to get a response
        guard let response = try? drop.client.post(apiURL + "/getMe") else {
            drop.console.error(TGReqError.NoResponse.rawValue, newLine: true)
            return nil
        }
        
        // Check if the response is valid
        if response.data["ok"]?.bool != true {
            drop.console.error(TGReqError.BadResponse.rawValue, newLine: true)
            return nil
        }
        
        // Attempt to extract the response
        let node = response.json!.node["result"]?.node
        guard let user = try? User(node: node, in: TGContext.response) else {
            drop.console.error(TGReqError.ResponseNotExtracted.rawValue, newLine: true)
            return nil
        }
        
        // Return the object
        return user
    }
    
    // Will let you manually fetch updates.
    public func getUpdates(incrementUpdate: Bool = true) -> [Polymorphic]? {
        // Call the bot API for any new messages
        let query = makeUpdateQuery()
        guard let response = try? drop.client.post(apiURL + "/getUpdates", query: query) else {
            drop.console.error(TGReqError.NoResponse.rawValue, newLine: true)
            return nil
        }
        
        // Get the results of the update request
        guard let result: Array = response.data["result"]?.array else {
            drop.console.error(TGReqError.ResponseNotExtracted.rawValue, newLine: true)
            return nil
        }
        return result
    }
    
    
    
    // Sends a message.  Must contain a chat ID, message text and an optional MarkupType.
    public func sendMessage(chatID: Int, text: String, replyMarkup: MarkupType?, parseMode: String = "", disableWebPreview: Bool = false, disableNtf: Bool = false, replyMessageID: Int = 0) -> Message? {
        var query: [String:CustomStringConvertible] = [
            "chat_id":chatID,
            "text": text,
            "disable_web_page_preview": disableWebPreview,
            "disable_notification": disableNtf
        ]
        
        // Check whether any other query needs to be added
        if replyMarkup != nil { query["reply_markup"] = replyMarkup!.getQuery() }
        if parseMode != "" { query["parse_mode"] = parseMode }
        if replyMessageID != 0 { query["reply_to_message_id"] = replyMessageID }
        
        // Try sending it!
        guard let response = try? drop.client.post(apiURL + "/sendMessage", query: query) else {
            drop.console.error(TGReqError.NoResponse.rawValue, newLine: true)
            return nil
        }
        
        //print(response)
        
        // Check if the response is valid
        if response.data["ok"]?.bool != true {
            drop.console.error(TGReqError.BadResponse.rawValue, newLine: true)
            return nil
        }
        
        // Attempt to extract the response
        let node = response.json!.node["result"]?.node
        guard let message = try? Message(node: node, in: TGContext.response) else {
            drop.console.error(TGReqError.ResponseNotExtracted.rawValue, newLine: true)
            return nil
        }
        
        return message
    }
    
    
    // Forwards a message of any kind.  On success, the sent Message is returned.
    public func forwardMessage(toChatID: Int, fromChatID: Int, fromMessageID: Int, disableNtf: Bool = false) -> Message? {
        let query: [String:CustomStringConvertible] = [
            "chat_id":toChatID,
            "from_chat_id": fromChatID,
            "message_id": fromMessageID,
            "disable_notification": disableNtf
        ]
        
        // Try sending it!
        guard let response = try? drop.client.post(apiURL + "/forwardMessage", query: query) else {
            drop.console.error(TGReqError.NoResponse.rawValue, newLine: true)
            return nil
        }
        
        // Check if the response is valid
        if response.data["ok"]?.bool != true {
            drop.console.error(TGReqError.BadResponse.rawValue, newLine: true)
            return nil
        }
        
        // Attempt to extract the response
        let node = response.json!.node["result"]?.node
        guard let message = try? Message(node: node, in: TGContext.response) else {
            drop.console.error(TGReqError.ResponseNotExtracted.rawValue, newLine: true)
            return nil
        }
        
        return message
    }
    
    
    // Sends a file that has already been uploaded.
    // The caption can't be used on all types...
    public func sendFile(chatID: Int, file: SendType, replyMarkup: MarkupType?, caption: String = "", disableNtf: Bool = false, replyMessageID: Int = 0) -> Message? {
        var query: [String:CustomStringConvertible] = [
            "chat_id":chatID]
        
        // Ensure only the files that can have caption types get a caption query
        //let captionTypes = ["audio", "photo", "video", "document", "voice"]
        //if caption != "" && captionTypes.index(of: file.messageTypeName) != nil { query["caption"] = caption }
        
        // Check whether any other query needs to be added
        if replyMarkup != nil { query["reply_markup"] = replyMarkup!.getQuery() }
        if replyMessageID != 0 { query["reply_to_message_id"] = replyMessageID }
        if disableNtf != false { query["disable_notification"] = disableNtf }
        
        // Combine the query built above with the one the file provides
        let finalQuery = query.reduce(file.getQuery(), { r, e in var r = r; r[e.0] = e.1; return r })
        
        // Try sending it!
        guard let response = try? drop.client.post(apiURL + file.method, query: finalQuery) else {
            drop.console.error(TGReqError.NoResponse.rawValue, newLine: true)
            return nil
        }
        
        // Check if the response is valid
        if response.data["ok"]?.bool != true {
            drop.console.error(TGReqError.BadResponse.rawValue, newLine: true)
            return nil
        }
        
        // Attempt to extract the response
        let node = response.json!.node["result"]?.node
        guard let message = try? Message(node: node, in: TGContext.response) else {
            drop.console.error(TGReqError.ResponseNotExtracted.rawValue, newLine: true)
            return nil
        }
        
        return message
    }
    
    /** I mean you're not "necessarily" uploading a file but whatever, it'll do for now */
    public func uploadFile(link: TGFileUpload, chatID: Int, markup: MarkupType?, caption: String = "", disableNtf: Bool = false, replyMessageID: Int = 0) {
        
        // Check to see if we need to upload this in the first place.
        // If not, send the file using the link.
        let search = cache.find(upload: link, bot: self)
        if search != nil {
            print("SENDING...")
            _ = sendFile(chatID: chatID, file: search!, replyMarkup: markup, caption: caption, disableNtf: disableNtf, replyMessageID: replyMessageID)
            return
        }
        
        // Obtain t
        let data = cache.get(upload: link)
        if data == nil { return }
        
        // Make the multipart/form-data
        let request = Response()
        var form: [String:Field] = [:]
        form["chat_id"] = Field(name: "chat_id", filename: nil, part: Part(headers: [:], body: String(chatID).bytes))
        form[link.type.rawValue] = Field(name: link.type.rawValue, filename: "NOODLE", part: Part(headers: [:], body: data!))
        // A filename is required here
        
        
        // Check whether any other query needs to be added
        if markup != nil { form["reply_markup"] = Field(name: "reply_markup", filename: nil, part: Part(headers: [:], body: try! markup!.makeJSON().makeBytes())) }
        if replyMessageID != 0 { form["reply_to_message_id"] = Field(name: "reply_to_message_id", filename: nil, part: Part(headers: [:], body: String(replyMessageID).bytes)) }
        if disableNtf != false { form["disable_notification"] = Field(name: "disable_notification", filename: nil, part: Part(headers: [:], body: String(disableNtf).bytes)) }
        
        
        // This is the "HEY, I WANT MY BODY TO BE LIKE THIS AND TO PARSE IT LIKE FORM DATA"
        request.formData = form
        let url = apiURL + "/" + link.type.method
        //print(url)
        //print(request)
        print("UPLOADING...")
        
        let queueDrop = drop
        
        uploadQueue.sync {
            let response = try! queueDrop.client.post(url, headers: request.headers, body: request.body)
            self.finishUpload(link: link, response: response)
            
            /*
            // Get the URL in a protected way
            guard let url = URL(string: url) else {
                print("Error: cannot create URL")
                return
            }
            // Build the body data set
            let bytes = request.body.bytes
            let data = Data(bytes: bytes!.array)
            
            // Build the URL request
            var req = URLRequest(url: url)
            
            // Add the right HTTP headers
            for header in request.headers {
                req.addValue(header.value, forHTTPHeaderField: header.key.key)
            }
            
            // Configure the request and set the payload
            req.httpMethod = "POST"
            req.httpBody = data
            req.httpShouldHandleCookies = false
            
            // Set the task
            let task = URLSession.shared.dataTask(with: req) {
                data, handler, error in
                
                let result = try! JSON(bytes: (data?.array)!)
                print(result)
            }
            
            // Make it rain.
            task.resume()
            */
        }
        return
    }
    
    public func finishUpload(link: TGFileUpload, response: Response) {
    
        // All you need is the correct URL with the body of the
//        guard let response = try? drop.client.post(url, headers: request.headers, body: request.body) else {
//            drop.console.error(TGReqError.NoResponse.rawValue, newLine: true)
//            return nil
//        }
        
        // Check if the response is valid
        if response.data["ok"]?.bool != true {
            drop.console.error(TGReqError.BadResponse.rawValue, newLine: true)
            return
        }
        
        // Attempt to extract the response
        let node = response.json!.node["result"]?.node
        guard let message = try? Message(node: node, in: TGContext.response) else {
            drop.console.error(TGReqError.ResponseNotExtracted.rawValue, newLine: true)
            return
        }
        
        // Add it to the cache
        _ = cache.add(upload: link, message: message)
        return

    }
    
    
    //////////////////////////////////////////////////////////////////////////////////
    //// TELEGRAM CHAT MANAGEMENT METHOD IMPLEMENTATIONS
    
    
    /* Use this method to kick a user from a group or a supergroup. In the case of supergroups, the user will not be able to return to the group on their own using invite links, etc., unless unbanned first. The bot must be an administrator in the group for this to work. Returns True on success. */
    public func sendChatAction(chatID: Int, action: ChatAction) {
        let query: [String:CustomStringConvertible] = [
            "chat_id": chatID,
            "action": action.rawValue
        ]
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/sendChatAction", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
    
    /* Use this method to get a list of profile pictures for a user. Returns a UserProfilePhotos object. */
    public func getUserProfilePhotos(userID: Int, offset: Int = 0, limit: Int = 100) {
        
        // I know this could be neater, figure something else later
        var adjustedLimit = limit
        if limit > 100 { adjustedLimit = 100 }
        
        let query: [String:CustomStringConvertible] = [
            "user_id": userID,
            "offset": offset,
            "limit": adjustedLimit
        ]
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/getUserProfilePhotos", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
    
    /* Use this method to get basic info about a file and prepare it for downloading. For the moment, bots can download files of up to 20MB in size. On success, a File object is returned. The file can then be downloaded via the link https://api.telegram.org/file/bot<token>/<file_path>, where <file_path> is taken from the response. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling getFile again. */
    public func getFile(fileID: Int) {
        let query: [String:CustomStringConvertible] = [
            "file_id": fileID
        ]
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/getFile", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
    
    /* Use this method to kick a user from a group or a supergroup. In the case of supergroups, the user will not be able to return to the group on their own using invite links, etc., unless unbanned first. The bot must be an administrator in the group for this to work. Returns True on success. */
    public func kickChatMember(chatID: Int, userID: Int) {
        let query: [String:CustomStringConvertible] = [
            "chat_id": chatID,
            "user_id": userID
        ]
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/getChatMember", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
    
    
    /* Use this method for your bot to leave a group, supergroup or channel. Returns True on success. */
    public func leaveChat(chatID: Int, userID: Int) {
        let query: [String:CustomStringConvertible] = [
            "chat_id":chatID,
            "user_id": userID
        ]
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/getChatMember", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
    
    
    
    /* Use this method to unban a previously kicked user in a supergroup. The user will not return to the group automatically, but will be able to join via link, etc. The bot must be an administrator in the group for this to work. Returns True on success. */
    public func unbanChatMember(chatID: Int, userID: Int) {
        let query: [String:CustomStringConvertible] = [
            "chat_id":chatID,
            "user_id": userID
        ]
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/getChatMember", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
    
    /* Use this method to get up to date information about the chat (current name of the user for one-on-one conversations, current username of a user, group or channel, etc.). Returns a Chat object on success. */
    public func getChat(chatID: Int) {
        let query: [String:CustomStringConvertible] = [
            "chat_id":chatID,
            ]
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/getChat", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
    
    // Use this method to get a list of administrators in a chat. On success, returns an Array of ChatMember.
    // Doesn't include other bots - if the chat is a group of supergroup and no admins were appointed, only the
    // creator will be returned.
    public func getChatAdministrators(chatID: Int) {
        let query: [String:CustomStringConvertible] = [
            "chat_id":chatID,
            ]
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/getChatAdministrators", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
    
    // Get the number of members in a chat. Returns Int on success.
    public func getChatMemberCount(chatID: Int) {
        let query: [String:CustomStringConvertible] = [
            "chat_id":chatID,
        ]
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/getChatMembersCount", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
    
    // Get information about a member of a chat. Returns a ChatMember object on success
    public func getChatMember(chatID: Int, userID: Int) {
        let query: [String:CustomStringConvertible] = [
            "chat_id":chatID,
            "user_id": userID
        ]
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/getChatMember", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////////
    //// TELEGRAM EDIT MESSAGE METHOD IMPLEMENTATIONS
    
    public func editMessageText(chatID: Int, messageID: Int = 0, text: String, replyMarkup: MarkupType?, parseMode: String = "", disableWebPreview: Bool = false, replyMessageID: Int = 0) {
        var query: [String:CustomStringConvertible] = [
            "chat_id":chatID,
            "text": text,
            "disable_web_page_preview": disableWebPreview,
        ]
        
        // Check whether any other query needs to be added
        if messageID != 0 { query["message_id"] = messageID }
        if replyMarkup != nil { query["reply_markup"] = replyMarkup!.getQuery() }
        if parseMode != "" { query["parse_mode"] = parseMode }
        if replyMessageID != 0 { query["reply_to_message_id"] = replyMessageID }
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/editMessageText", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
    
    public func editMessageCaption(chatID: Int, messageID: Int = 0, text: String, replyMarkup: MarkupType?, replyMessageID: Int = 0) {
        var query: [String:CustomStringConvertible] = [
            "chat_id":chatID,
            "text": text,
            ]
        
        // Check whether any other query needs to be added
        if messageID != 0 { query["message_id"] = messageID }
        if replyMarkup != nil { query["reply_markup"] = replyMarkup!.getQuery() }
        if replyMessageID != 0 { query["reply_to_message_id"] = replyMessageID }
        
        // Try sending it!
        do {
            let _ = try drop.client.post(apiURL + "/editMessageCaption", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
    
    public func editMessageReplyMarkup(chatID: Int, messageID: Int = 0, replyMarkup: MarkupType?, replyMessageID: Int = 0) {
        var query: [String:CustomStringConvertible] = [
            "chat_id":chatID,
            ]
        
        // Check whether any other query needs to be added
        if messageID != 0 { query["message_id"] = messageID }
        if replyMarkup != nil { query["reply_markup"] = replyMarkup!.getQuery() }
        if replyMessageID != 0 { query["reply_to_message_id"] = replyMessageID }
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/editMessageReplyMarkup", query: query)
        }
        catch {
            print(error)
        }
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////
    //// TELEGRAM CALLBACK METHOD IMPLEMENTATIONS
    
    
    // Send answers to callback queries sent from inline keyboards.
    // The answer will be displayed to the user as a notification at the top of the chat screen or as an alert.
    public func answerCallbackQuery(queryID: String, text: String = "", showAlert: Bool = false, url: String = "", cacheTime: Int = 0) {
        var query: [String:CustomStringConvertible] = [
            "callback_query_id":queryID,
            "show_alert": showAlert,
            "cache_time": cacheTime
        ]
        
        // Check whether any other query needs to be added
        if text != "" { query["text"] = text }
        if url != "" { query["url"] = url }
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/answerCallbackQuery", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
    
    // Use this method to send answers to an inline query. On success, True is returned.
    // No more than 50 results per query are allowed.
    public func answerInlineQuery(inlineQueryID: String, results: [InlineResult], cacheTime: Int = 300, isPersonal: Bool = false, nextOffset: Int = 0, switchPM: String = "", switchPMParam: String = "") {
        var query: [String:CustomStringConvertible] = [
            "inline_query_id": inlineQueryID
        ]
        
        var resultQuery: [JSON] = []
        for result in results {
            let json = try! result.makeJSON()
            resultQuery.append(json)
        }
        
        query["results"] = try! resultQuery.makeJSON().serialize().toString()
        
        // Check whether any other query needs to be added
        if cacheTime != 300 { query["cache_time"] = cacheTime }
        if isPersonal != false { query["is_personal"] = isPersonal }
        if nextOffset != 0 { query["next_offset"] = nextOffset }
        if switchPM != "" { query["switch_pm_text"] = switchPM }
        if switchPMParam != "" { query["switch_pm_parameter"] = switchPMParam }
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/answerInlineQuery", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
    
    
    
    //////////////////////////////////////////////////////////////////////////////////
    //// TELEGRAM GAME METHOD IMPLEMENTATIONS
    
    
    /* Use this method to send a game. On success, the sent Message is returned. */
    public func sendGame(chatID: Int, gameName: String, replyMarkup: MarkupType?, disableNtf: Bool = false, replyMessageID: Int = 0) {
        var query: [String:CustomStringConvertible] = [
            "chat_id":chatID,
            "game_short_name": gameName
        ]
        
        // Check whether any other query needs to be added
        if replyMarkup != nil { query["reply_markup"] = replyMarkup!.getQuery() }
        if replyMessageID != 0 { query["reply_to_message_id"] = replyMessageID }
        if disableNtf != false { query["disable_notification"] = disableNtf }
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/sendGame", query: query)
        }
        catch {
            print(error)
        }
    }
    
    /* Use this method to set the score of the specified user in a game. On success, if the message was sent by the bot, returns the edited Message, otherwise returns True. Returns an error, if the new score is not greater than the user's current score in the chat and force is False. */
    public func setGameScore(userID: Int, score: Int, force: Bool = false, disableEdit: Bool = false, chatID: Int = 0, messageID: Int = 0, inlineMessageID: Int = 0) {
        var query: [String:CustomStringConvertible] = [
            "user_id":userID,
            "score": score
        ]
        
        // Check whether any other query needs to be added
        if force != false { query["force"] = force }
        if disableEdit != false { query["disable_edit_message"] = disableEdit }
        
        // THIS NEEDS EDITING PROBABLY, NOT NICE DESIGN
        if inlineMessageID == 0 {
            query["chat_id"] = chatID
            query["message_id"] = messageID
        }
        
        else {
            query["inline_message_id"] = inlineMessageID
        }
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/setGameScore", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
    
    /* Use this method to get data for high score tables. Will return the score of the specified user and several of his neighbors in a game. On success, returns an Array of GameHighScore objects.
 
 This method will currently return scores for the target user, plus two of his closest neighbors on each side. Will also return the top three users if the user and his neighbors are not among them. Please note that this behavior is subject to change. */
    public func getGameHighScores(userID: Int, chatID: Int = 0, messageID: Int = 0, inlineMessageID: Int = 0) {
        var query: [String:CustomStringConvertible] = [
            "user_id":userID
        ]
        
        // THIS NEEDS EDITING PROBABLY, NOT NICE DESIGN
        if inlineMessageID == 0 {
            query["chat_id"] = chatID
            query["message_id"] = messageID
        }
            
        else {
            query["inline_message_id"] = inlineMessageID
        }
        
        // Try sending it!
        do {
            _ = try drop.client.post(apiURL + "/getGameHighScores", query: query)
            //print(result)
        }
        catch {
            print(error)
        }
    }
}


