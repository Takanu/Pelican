
import Dispatch     // Linux thing.
import Foundation
import Vapor
import FluentProvider
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

/**
Defines the kind of action you wish a chat action to specify.  (This description sucks).
*/
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

/**
Errors relating to Pelican setup.
*/
enum TGBotError: String, Error {
  case KeyMissing = "The API key hasn't been provided.  Please provide a \"token\" for Config/pelican.json, containing your bot token."
  case EntryMissing = "Pelican hasn't been given an session setup closure.  Please provide one using `sessionSetupAction`."
}

/**
Errors related to request fetching.
*/
enum TGReqError: String, Error {
  case NoResponse = "The request received no response."
  case UnknownError = "Something happened, and i'm not sure what!"
  case BadResponse = "Telegram responded with \"NOT OKAY\" so we're going to trust that it means business."
  case ResponseNotExtracted = "The request could not be extracted."
}

/**
Errors related to update processing.  Might merge the two?
*/
enum TGUpdateError: String, Error {
  case BadUpdate = "The message received from Telegram was malformed or unable to be processed by this bot."
}

/** 
A deprecated internal type used to enable models to switch between node-type conversion for response purposes, 
and that for databasing purposes.
*/
public enum TGContext: Context {
  case response
  case db
}




/**
The Vapor Provider for building Telegram bots!  Interact with this class directly when 
initialising your Vapor app and setting up your Telegram bot.

To get started with Pelican, you'll need to place the code below as setup before running the app.
You'll also need to add your API token as a `token` inside `config/pelican.json` (create it if you don't have the file),
to assign it to your bot and start receiving updates.  You can get your API token from @BotFather.

## Pelican JSON Contents
```
{
"token": "INSERT:YOUR-KEY-RIGHT-HERE"
}
```

## Pelican Basic Setup

```
let config = try Config()
let pelican = try Pelican(config: config)

pelican.sessionSetupAction = setupBot
pelican.setPoll(interval: 1)

try config.addProvider(pelican)
let drop = try Droplet(config)
try drop.run()

```
*/
public final class Pelican: Vapor.Provider {
	public static let repositoryName = "Pelican"

	/// Wait whats this?
  public let message: String = "Rawr."
  //public var provided: Providable { return Providable() }
	
	/// The droplet this provider is running on.
  var drop: Droplet
	/// The cache system responsible for handling the re-using of already uploaded files and assets, to preserve system resources.
  var cache: CacheManager
	/// The API key assigned to your bot.  PLEASE DO NOT ASSIGN IT HERE, ADD IT TO A JSON FILE INSIDE config/pelican.json as a "token".
  var apiKey: String
	/// The combination of the API request URL and your API token.
  var apiURL: String
	/// Defines an object to be used for custom data, to be used purely for cloning into newly-created ChatSessions.  DO NOT EDIT CONTENTS.
  private var customData: NSCopying?
  
  // Variables used for long polling
  public var offset: Int = 0
  public var limit: Int = 100
  public var timeout: Int = 0
  public var allowedUpdates: [UpdateType] = []						// Leave empty if all are allowed, otherwise specify.
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
  
  // ChatSessions
	private var chatSessions: [Int:ChatSession] = [:]						// The currently active sessions, ordered by how recently it was interacted with (longer = smaller index).
  private var chatSessionActivity: [ChatSession] = []					// Records when a session was last used, to keep track of when sessions need to be closed.
  private var chatSessionEvents: [Int:ChatSession] = [:]			// Used for keeping track of sessions that have events.
	private var userSessions: [Int:UserSession] = [:]						// Keeps track of the individual users currently interacting with the bot.
	
	public var getChatSessions: [Int:ChatSession]	{ return chatSessions }
	public var getUserSessions: [Int:UserSession] { return userSessions }
	
  public var maxChatSessions: Int = 0                            // The maximum number of sessions the bot will support before it stops people from using it.  Leave at 0 for no limit.
  public var maxChatSessionsAction: ((Pelican, Chat) -> ())? // Define an action if desired to perform when someone tries this way
  public var defaultMaxChatSessionTime: Int = 0                  // The maximum amount of time in seconds that a session should last for.
	
	public var unfilteredChatUpdates: ((ChatUpdate) -> ())? // What happens with the updates that didn't find a place to be filtered.
	public var unfilteredUserUpdates: ((UserUpdate) -> ())? // What happens with the updates that didn't find a place to be filtered.
  public var sessionSetupAction: ((ChatSession) -> ())?  // What happens when the session begins,
  public var sessionEndAction: ((ChatSession) -> ())?  // What should be run when the session ends.  Could be nothing!
	
	
  // Flood Limit
  public var floodLimit: FloodLimit = FloodLimit(limit: 250, range: 300, breachLimit: 2, breachReset: 500)  // Settings that define flood limit restrictions for each session
  public var floodLimitWarning: ((UserSession) -> ())? // An optional warning to send to people the first time they hit the flood warning.
	
	
  // Response Settings
  public var responseLimit: Int = 0  // The number of times a session will respond to a message in a given poll interval before ignoring them.  Set as 0 for no limit.
  public var restrictUsers: Bool = false // Restricts the users that can use a session to only those specified in the session list if true.
	
	
	
  // Blacklist
	/// The moderator system, used for blacklisting and whitelisting users and chats to either prevent or allow them to use the bot.
	public var mod: Moderator
	/// Define an action if someone enters the blacklist.
  public var blacklistPrepareAction: ((Pelican, Chat) -> ())?

	public func boot(_ config: Config) throws {
		print("*shrug")
	}
  
  // Provider conforming functions
  public init(config: Config) throws {
    guard let token = config["pelican", "token"]?.string else {
      throw TGBotError.KeyMissing
    }
		
		Node.fuzzy = [Row.self, JSON.self, Node.self]
		/*
			[Chat.self, Message.self, MessageEntity.self, Photo.self, PhotoSize.self,
									Audio.self, Document.self, Sticker.self, Video.self, Voice.self, Contact.self, Location.self,
									Venue.self, UserProfilePhotos.self]
		*/
		
		self.mod = Moderator()
    self.cache = CacheManager()
    self.apiKey = token
    self.apiURL = "https://api.telegram.org/bot" + apiKey
		
    self.uploadQueue = DispatchQueue(label: "TG-Upload",
                                     qos: .background,
                                     target: nil)
    self.drop = try Droplet()
		try! cache.setBundlePath(drop.config.publicDir)
  }
	
	
  public func afterInit(_ drop: Droplet) {
    self.drop = drop
		self.mod.bot = self
  }
	
	
  public func beforeRun(_ drop: Droplet) {
    if self.sessionSetupAction == nil {
      drop.console.warning(TGBotError.EntryMissing.rawValue, newLine: true)
    }
    
    if ignoreInitialUpdates == true {
      _ = self.getUpdateSets()
    }
    
    if allowedUpdates.count == 0 {
      for type in iterateEnum(UpdateType.self) {
        allowedUpdates.append(type)
      }
    }
    
    started = true
    updateQueue!.start()
    //Jobs.add(interval: .seconds(Double(pollInterval))) {
    //    self.filterUpdates()
    //}
  }
  
  public func boot(_ drop: Droplet) {}
  
	
	
	
	
	
  /**
	Allows you to assign a custom type that will get used for each ChatSession that is created.
	Once assigned, this can then be accessed in the ChatSession by using `session.data`.
	*/
  public func setCustomData(_ data: NSCopying) {
    self.customData = data.copy(with: nil) as? NSCopying
  }
	
	/**
	Sets the frequency at which the bot looks for updates from users to act on.  If a timeout is set,
	this becomes the length of time it takes after handling a set of updates to request more from Telegram,
	until the timeout amount is reached.
	*/
  public func setPoll(interval: Int) {
    updateQueue = UpdateQueue(interval: TimeInterval(interval)) {
      self.filterUpdates()
    }
    
    pollInterval = interval
  }
	
	/**
	An internal method for creating an update query string for easy use when requesting updates.
	*/
  internal func makeUpdateQuery() -> [String:NodeConvertible] {
    var keys: [String:NodeConvertible] = [
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
  
  /**
	Requests a set of updates from Telegram, based on the poll, offset, timeout and update limit settings
	assigned to Pelican.
	- returns: A `TelegramUpdateSet` if successful, or nil if otherwise.
	*/
	public func getUpdateSets() -> ((chat: [ChatUpdate], user: [UserUpdate]))? {
    let query = makeUpdateQuery()
    
    guard let response = try? drop.client.get(apiURL + "/getUpdates", query: query) else {
      drop.console.error(TGReqError.NoResponse.rawValue, newLine: true)
      return nil
    }
		
		
    // Get the basic result data
    let result: Array = response.data["result"]?.array ?? []
    let messageCount = result.count
    
    // Make the collection types
		var chatUpdates: [ChatUpdate] = []
		var userUpdates: [UserUpdate] = []
		
		
    // Iterate through the collected messages
    for i in 0..<messageCount {
      let update_id = response.data["result", i, "update_id"]?.int ?? -1
      
      
      // This is just a plain old message
      if allowedUpdates.contains(UpdateType.message) {
        if (response.data["result", i, "message"]) != nil {
					
					// Find and build a node based on the search.
					guard let messageNode = response.json?.makeNode(in: nil)["result", i, "message"] else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
					
					guard let message = try? Message(row: Row(messageNode)) else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
          chatUpdates.append(ChatUpdate(withData: message as ChatUpdateModel))
        }
      }
      
      // This is if a message was edited
      if allowedUpdates.contains(UpdateType.editedMessage) {
        if (response.data["result", i, "edited_message"]) != nil {
          guard let messageNode = response.json?.makeNode(in: nil)["result", i, "edited_message"] else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
					guard let message = try? Message(row: Row(messageNode)) else {
						drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
						offset = update_id + 1
						continue
					}
					
          chatUpdates.append(ChatUpdate(withData: message as ChatUpdateModel))
        }
      }
      
      // This is for a channel post
      if allowedUpdates.contains(UpdateType.channelPost) {
        if (response.data["result", i, "channel_post"]) != nil {
          guard let messageNode = response.json?.makeNode(in: nil)["result", i, "channel_post"] else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
					guard let message = try? Message(row: Row(messageNode)) else {
						drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
						offset = update_id + 1
						continue
					}
					
          chatUpdates.append(ChatUpdate(withData: message as ChatUpdateModel))
        }
      }
      
      // This is for an edited channel post
      if allowedUpdates.contains(UpdateType.editedChannelPost) {
        if (response.data["result", i, "edited_channel_post"]) != nil {
          guard let messageNode = response.json?.makeNode(in: nil)["result", i, "edited_channel_post"] else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }
          
					guard let message = try? Message(row: Row(messageNode)) else {
						drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
						offset = update_id + 1
						continue
					}
					
          chatUpdates.append(ChatUpdate(withData: message as ChatUpdateModel))
        }
      }
      
      // COME BACK TO THESE LATER
      // This type is for when someone tries to search something in the message box for this bot
      if allowedUpdates.contains(UpdateType.inlineQuery) {
        if (response.data["result", i, "inline_query"]) != nil {
          guard let messageNode = response.json?.makeNode(in: nil)["result", i, "inline_query"] else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
						print("inline_query")
            offset = update_id + 1
            continue
          }
          
					guard let message = try? InlineQuery(row: Row(messageNode)) else {
						drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
						print("inline_query")
						offset = update_id + 1
						continue
					}
					
          userUpdates.append(UserUpdate(withData: message as UserUpdateModel))
        }
      }
      
      // This type is for when someone has selected an search result from the inline query
      if allowedUpdates.contains(UpdateType.chosenInlineResult) {
        if (response.data["result", i, "chosen_inline_result"]) != nil {
          guard let messageNode = response.json?.makeNode(in: nil)["result", i, "chosen_inline_result"] else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
						print("Chosen Inline Result")
            offset = update_id + 1
            continue
          }
          
					guard let message = try? ChosenInlineResult(row: Row(messageNode)) else {
						drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
						print("Chosen Inline Result")
						offset = update_id + 1
						continue
					}
					
          userUpdates.append(UserUpdate(withData: message as UserUpdateModel))
        }
      }
      
      /// Callback Query handling (receiving button presses for inline buttons with callback data)
      if allowedUpdates.contains(UpdateType.callbackQuery) {
        if (response.data["result", i, "callback_query"]) != nil {
          guard let messageNode = response.json?.makeNode(in: nil)["result", i, "callback_query"] else {
            drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
						print("Callback Query")
            offset = update_id + 1
            continue
          }
          
					guard let message = try? CallbackQuery(row: Row(messageNode)) else {
						drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
						print("Callback Query")
						offset = update_id + 1
						continue
					}
					
          chatUpdates.append(ChatUpdate(withData: message as ChatUpdateModel))
        }
      }
      
      offset = update_id + 1
    }
    
    return (chatUpdates, userUpdates)
  }
	
	
	
  /**
	Used by the in-built long polling solution to match updates to sessions.
	### EDIT/REMOVE IN UPCOMING REFACTOR
	*/
  internal func filterUpdates() {
    //print("START")
    guard let updates = getUpdateSets() else {
      return
    }
    
    // Check the global timer for any scheduled events
    globalTimer += pollInterval
    checkChatSessionActivity()
    checkChatSessionQueues()
		
		
		// Filter the update to a session if one exists for the chat.
		for update in updates.chat {
			
			// If it's in the Moderator blacklist, drop immediately
				
			if chatSessions[update.chatID] != nil {
				
				let session = chatSessions[update.chatID]!
				session.filterUpdate(update)
				continue
			}
			
			// If we didn't find a session, call the unfiltered function to decide if one should be made
			if unfilteredChatUpdates != nil {
				unfilteredChatUpdates!(update)
			}
			
			
			// If the update had a user, make sure the UserSession duties are carried out
			if update.from != nil {
				
				if userSessions[update.from!.tgID] == nil {
					
					//let session = createUserSession(user: update.from!, setup: nil)
					//session.bumpFlood()
				}
				
				else {
					
					//let session = userSessions[update.from!.tgID]
					//session.bumpFlood()
				}
			}
		}
		
		
		// Filter user updates to existing user sessions, or attempt to create one if none exists.
		for update in updates.user {
			
			if userSessions[update.from.tgID] != nil {
				
				let session = userSessions[update.from.tgID]
				session?.filterUpdate(update: update)
			}
			
			if unfilteredUserUpdates != nil {
				unfilteredUserUpdates!(update)
			}
			
			
			// If the update had a user, make sure the UserSession duties are carried out
			if userSessions[update.from.tgID] == nil {
				
				//let session = createUserSession(user: update.from!, setup: nil)
				//session.bumpFlood()
			}
				
			else {
				
				//let session = userSessions[update.from!.tgID]
				//session.bumpFlood()
			}
		}
  }
	
	
	/**
	Attempts to create a session based on given criteria.  The given criteria determines whether the session is used to handle updates
	*/
	public func createChatSession(chatID: Int, setup: (ChatSession) -> ()) {
		
		// If a chat session already exists, return.
		if chatSessions[chatID] != nil { return }
		
		// If the chat ID is in the Moderator blacklist, return.
		if mod.checkBlacklist(chatID: chatID) == true { return }
		
		print(">>>>> ADDING NEW SESSION <<<<<")
		
		
		// If we've reached the maximum number of allowed sessions, send them a message if available.
		if chatSessions.count >= maxChatSessions && maxChatSessions != 0 {
			print("ChatSession count reached.  Deferring.")
			//if maxChatSessionsAction != nil { maxChatSessionsAction!(self, chat) }
			return
		}
		
		
		// If we're still here, add them.
		if sessionSetupAction == nil { print(TGBotError.EntryMissing.rawValue) ; return }
		let session = ChatSession(bot: self, chatID:chatID, data: customData, floodLimit: floodLimit, setup: self.sessionSetupAction!, sessionEndAction: self.sessionEndAction)
		session.postInit()
		session.responseLimit = self.responseLimit
		
		chatSessions[chatID] = session
		chatSessionActivity.append(session)
		
		print("ChatSession added.")
		print("Current Active ChatSessions: ")
		print(chatSessions)
	}
	
	/**
	Attempts to create a user session, as long as one currently doesn't exist.
	*/
	public func createUserSession(user: User, setup: ((UserSession) -> ())?) -> UserSession? {
		
		// Before we create a session, check the user isn't in the Moderator blacklist.
		if mod.checkBlacklist(userID: user.tgID) == true { return nil }
		
		let session = UserSession(bot: self, user: user, floodLimit: floodLimit)
		return session
	}
	
  /**
	Bumps a session up the activity queue based on perceived activity.  Only bump if it's clear that the session
	has been interacted with.
	*/
  internal func bumpChatSession(_ session: ChatSession) {
    
    // Find the session to be bumped up
    for (index, value) in chatSessionActivity.enumerated() {
      
      // If found, pull it from the stack and add it to the end.
      if value.chatID == session.chatID {
        chatSessionActivity.remove(at: index)
        chatSessionActivity.append(session)
      }
    }
  }
  
  /**
	Reviews session activity using the `sessionActivity`, and decided whether any sessions need to be removed based on their timeout values.
	*/
  internal func checkChatSessionActivity() {
    // If no max session time is set (and it really should be) , ignore checks.
    if defaultMaxChatSessionTime == 0 { return }
    
    // While the first session is timed out, end it and remove it from all stacks.
    while chatSessionActivity.first?.timedOut == true {
      
      let session = chatSessionActivity.first!
      //print("ChatSession Time Out - ", (session.chat.title ?? session.chat.firstName!))
      //print(String(session.chat.tgID) + " - " + (session.chat.title ?? session.chat.firstName!))
      
      if session.sessionEndAction != nil {
        session.sessionEndAction!(session)
      }
      
      // Remove the session from all arrays
      chatSessions.removeValue(forKey: session.chatID)
      chatSessionEvents.removeValue(forKey: session.chatID)
      chatSessionActivity.remove(at: 0)
      
      //print("ChatSession Removed.")
      //print("Current Active ChatSessions: ")
      //print(sessions)
    }
  }
  
  
  
  /**
	Adds a session to the list of sessions that have active events/
	*/
  internal func addChatSessionEvent(session: ChatSession) {
    if chatSessionEvents[session.chatID] == nil {
      //print("NEW SESSION EVENT ADDED")
      chatSessionEvents[session.chatID] = session
      //print(sessionsEvents)
    }
  }
  
  
  /** 
	Checks all the currently active session events.  The call increments their timers and executes any actions that
	need executing.
	*/
  internal func checkChatSessionQueues() {
    for session in chatSessionEvents {
      
      let result = session.value.queue.incrementTimer()
      if result == true {
        //print("SESSION EVENTS COMPLETE, REMOVING...")
        chatSessionEvents.removeValue(forKey: session.key)
        //print(sessionsEvents)
      }
    }
  }
	
	
	/**
	Removes a specified session from being run on Pelican.
	This will not call the session endChatSessionAction, this function assumes it is being called from the session itself
	if it needs to be called before removal.
	*/
	public func removeChatSession(chatID: Int) {
		//print("REMOVING SESSION - ", (session.chat.title ?? session.chat.firstName!))
		chatSessions.removeValue(forKey: chatID)
		chatSessionEvents.removeValue(forKey: chatID)
		
		for (index, value) in chatSessionActivity.enumerated() {
			if value.chatID == chatID {
				chatSessionActivity.remove(at: index)
			}
		}
	}
	
	
	/**
	Removes a specified user session from Pelican.
	This doesn't stop the session from being re-created in the future (unless it was also added to the Moderator Blacklist).
	*/
	public func removeUserSession(userID: Int) {
		
		userSessions.removeValue(forKey: userID)
	}
}
