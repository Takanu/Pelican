
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
	private var lastExecuteTime: TimeInterval
  private let execute: () -> Void
  private var operation: DispatchWorkItem?
  
  init(interval: TimeInterval, execute: @escaping () -> Void) {
    self.interval = interval
		self.lastExecuteTime = TimeInterval.init(0)
    self.execute = execute
		
		
  }
	
  func start() {
		
		self.operation = DispatchWorkItem(qos: .userInteractive, flags: .enforceQoS) { [weak self] in
			
			// Record the starting time and execute the loop
			let startTime = Date()
			self?.execute()
			
			defer {
				
				// Build a time interval for the loop
				self?.lastExecuteTime = abs(startTime.timeIntervalSinceNow)
				self?.start()
			}
			
		}
		
		// Account for loop time in the asynchronous delay.
		let delayTime = interval - lastExecuteTime
		
		// If the delay time left is below 0, execute the loop immediately.
		if delayTime <= 0 {
		 	queue.async(execute: self.operation!)
		}
		
		// Otherwise use the built delay time.
		else {
			queue.asyncAfter(wallDeadline: .now() + delayTime, execute: self.operation!)
		}
		
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
	
	
	// CORE PROPERTIES
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
	
	
  // CONNECTION SETTINGS
  public var offset: Int = 0
  public var limit: Int = 100
  public var timeout: Int = 0
	
	/// The maximum number of times the bot will attempt to get a response before it logs an error.
	public var maxRequestAttempts: Int = 0
	/// Defines what update types the bot will receive.  Leave empty if all are allowed, or otherwise specify to optimise the bot.
  public var allowedUpdates: [UpdateType] = []
	/// If true, the bot will ignore any historic messages it has received while it has been offline.
  public var ignoreInitialUpdates: Bool = true
  private var started: Bool = false
  public var hasStarted: Bool { return started }
	
	
  // QUEUES
	/// The time the bot started operating.
	var timeStarted: Date
	/// The time the last update the bot has received from Telegram.
	var timeLastUpdate: Date
	
  fileprivate var updateQueue: UpdateQueue?
  var uploadQueue: DispatchQueue
  var pollInterval: Int = 0
  var globalTimer: Int = 0        // Used for executing scheduled events.
  public var getTime: Int { return globalTimer }
	
	
  // SESSIONS
	/// The sets of sessions that are currently active, encapsulated within their respective builders.
	private var sessions: [SessionBuilder] = []
	/// The schedule system for sessions to use to delay the execution of actions.
	public var schedule = Schedule()
	
	
  // Blacklist
	/// The moderator system, used for blacklisting and whitelisting users and chats to either prevent or allow them to use the bot.
	public var mod: Moderator
	/// Define an action if someone enters the blacklist.
  public var blacklistPrepareAction: ((Pelican, Chat) -> ())?
	
	
	// Boots the provider?
	public func boot(_ config: Config) throws {
		print("*shrug")
	}
	
	
  // Provider conforming functions
  public init(config: Config) throws {
		
		// Obtain the token from pelican.json
    guard let token = config["pelican", "token"]?.string else {
      throw TGBotError.KeyMissing
    }
		
		Node.fuzzy = [Row.self, JSON.self, Node.self]
		/*
			[Chat.self, Message.self, MessageEntity.self, Photo.self, PhotoSize.self,
									Audio.self, Document.self, Sticker.self, Video.self, Voice.self, Contact.self, Location.self,
									Venue.self, UserProfilePhotos.self]
		*/
		
		// Initialise controls and timers
		self.mod = Moderator()
    self.cache = CacheManager()
    self.apiKey = token
    self.apiURL = "https://api.telegram.org/bot" + apiKey
		
		// Initialise timers
		self.timeStarted = Date()
		self.timeLastUpdate = Date()
		
		// Initialise upload queue and droplet
    self.uploadQueue = DispatchQueue(label: "TG-Upload",
                                     qos: .background,
                                     target: nil)
		
		// This is a bit dodgy
    self.drop = try Droplet()
		try! cache.setBundlePath(drop.config.publicDir)
  }
	
	
  public func afterInit(_ drop: Droplet) {
    self.drop = drop
  }
	
	
  public func beforeRun(_ drop: Droplet) {
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
	public func getUpdateSets() -> ([Update])? {
		
		print("UPDATE START")
		
    let query = makeUpdateQuery()
    
    guard let response = try? drop.client.get(apiURL + "/getUpdates", query: query) else {
      drop.console.error(TGReqError.NoResponse.rawValue, newLine: true)
      return nil
    }
		
		
    // Get the basic result data
    let result: Array = response.data["result"]?.array ?? []
    let messageCount = result.count
    
    // Make the collection types
		var updates: [Update] = []
		
		
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
          
          updates.append(Update(withData: message as UpdateModel, node: messageNode))
        }
      }
			
			/*
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
					
					updates.append(Update(withData: message as UpdateModel, node: messageNode))
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
					
          updates.append(Update(withData: message as UpdateModel, node: messageNode))
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
					
          updates.append(Update(withData: message as UpdateModel, node: messageNode))
        }
      }
			*/
      
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
					
          updates.append(Update(withData: message as UpdateModel, node: messageNode))
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
					
          updates.append(Update(withData: message as UpdateModel, node: messageNode))
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
					
          updates.append(Update(withData: message as UpdateModel, node: messageNode))
        }
      }
      
      offset = update_id + 1
    }
    
    return updates
  }
	
	
	
  /**
	Used by the in-built long polling solution to match updates to sessions.
	### EDIT/REMOVE IN UPCOMING REFACTOR
	*/
  internal func filterUpdates() {
		
    print("START FILTER")
		
		// Get updates from Telegram
    guard let updates = getUpdateSets() else {
      return
    }
		
		
    // Check the global timer for any scheduled events
    globalTimer += pollInterval
    //checkChatSessionQueues()
		
		
		// Filter the update to the current builders.
		for update in updates {
			
			
			// Collect a list of builders that will accept the update.
			
			var captures: [SessionBuilder] = []
			
			for builder in sessions {
				
				if builder.checkUpdate(update) == true {
					captures.append(builder)
				}
			}
			
			
			// If the list is longer than 1, decide based on the optional
			// collision function type what should happen to Session that qualifies
			// for the update.
			
			var executables: [SessionBuilder] = []
			
			if captures.count > 1 {
				
				for capture in captures {
					
					if capture.collision == nil { executables.append(capture) }
					
					else {
						
						let response = capture.collision!(self, update)
						
						if response == .include {
							let session = capture.getSession(bot: self, update: update)!
							update.linkedSessions.append(session)
						}
						
						else if response == .execute {
							executables.append(capture)
						}
						
						
					}
				}
			}
			
			else {
					executables = captures
			}
			
			
			// Execute what executables are left
			for builder in executables {
				_ = builder.execute(bot: self, update: update)
			}
		}
		
		print(updates)
		
		
		// Check the schedule.
		schedule.run()
		
		
		// Update the last active time.
		timeLastUpdate = Date()
		print("UPDATE END")
		
  }
	
	/**
	Sends the given requests to Telegram.
	- note: At some point this will also collect and use content sent back from Telegram in a way that makes sense,
	but I haven't thought that far yet.
	*/
	func sendRequest(_ request: TelegramRequest) -> TelegramResponse {
		
		// Build a new request with the correct URI and fetch the other data from the Session Request
		let vaporRequest = Request(method: .post, uri: apiURL + "/" + request.methodName)
		
		if request.query.values.count != 0 {
			vaporRequest.query = try! request.query.makeNode(in: nil)
		}
		
		if request.form.values.count != 0 {
			vaporRequest.formData = request.form
		}
		
		// Attempt to send it and get a TelegramResponse from it.
		let tgResponse = TelegramResponse(response: try! drop.client.respond(to: vaporRequest))
		
		return tgResponse
		
	}
	
	/**
	Handles a specific event sent from a Session.
	*/
	func sendEvent(_ event: SessionEvent) {
		
	}
	
	
	/**
	Adds a new builder to the bot, enabling the automated creation and filtering of updates to your defined Session types.
	*/
	public func addBuilder(_ builder: SessionBuilder) {
		
		// Create a generator for the Builder ID and cycle through until we can make sure it's unique
		var generator = Xoroshiro(seed: (0,128))
		
		var id = 0
		while id != 0 && sessions.contains(where: {$0.getID == id}	) == false {
			id = Int(generator.random32())
		}
		
		// Set the ID and add the builder
		builder.setID(id)
		sessions.append(builder)
	}
	
	
	
	/*
	
	/**
	Checks Pelican's User and Chat session lists to see if any sessions have timed out, and removes the ones that have.
	- parameter amount: The amount of sessions in total that the function will check.  Set to 0 to check all stored sessions.
	- parameter resetList: Pelican remembers the sessions you have yet to check if the `amount` parameter is not 0.  Set this to false if you wish Pelican to continue
	checking from where it left off on the list, or false if you want it to reset it's checks.
	- note: If you haven't set `enableTimeoutChecks` to false, this will automatically be performed by Pelican based on the check frequency you have set.
	*/
	public func checkTimeouts(amount: Int, resetList: Bool) {
		
		if chatSessionActivity.count == 0 && userSessionActivity.count == 0 { return }
		
		if amount == 0 {
			
			for session in chatSessionActivity.values {
				if session.hasTimeout == true {
					
					removeChatSession(chatID: session.chatID)
				}
			}
			
			for session in userSessionActivity.values {
				if session.hasTimeout == true {
					
					removeUserSession(userID: session.userID)
				}
			}
		}
			
		
		
		else {
			
			// If we have been requested to reset the leftover timeout checks, do it!
			if resetList == true {
				chatSessionActivityLeft = chatSessionActivity.values.array
				userSessionActivityLeft = userSessionActivity.values.array
			}
			
			// Build the ratios between chats and users, and use that to build a total for each
			let total = chatSessionActivity.values.count + userSessionActivity.values.count
			let chatRatio = chatSessionActivity.values.count / total
			let userRatio = userSessionActivity.values.count / total
			
			var chatCheckCount = chatRatio * amount
			var userCheckCount = userRatio * amount
			
			if chatCheckCount > chatSessionActivity.count { chatCheckCount = chatSessionActivity.count }
			if userCheckCount > userSessionActivity.count { userCheckCount = userSessionActivity.count }
			
			
			for _ in 0..<userCheckCount {
				
				// If the leftover array equals 0, populate them.
				if chatSessionActivityLeft.count == 0 {
					chatSessionActivityLeft = chatSessionActivity.values.array
				}
				
				let session = chatSessionActivityLeft.removeFirst()
				if session.hasTimeout == true {
					
					removeChatSession(chatID: session.chatID)
				}
			}
			
			for _ in 0..<chatCheckCount {
				
				// If the leftover array equals 0, populate them.
				if userSessionActivityLeft.count == 0 {
					userSessionActivityLeft = userSessionActivity.values.array
				}
				
				let session = userSessionActivityLeft.removeFirst()
				if session.hasTimeout == true {
					
					removeUserSession(userID: session.userID)
				}
			}
		}
		
	}
	
	
	/**
	Attempts to create a session based on given criteria.  The given criteria determines whether the session is used to handle updates
	*/
	public func createChatSession(chatID: Int, setup: (ChatSession) -> ()) -> ChatSession? {
		
		// If a chat session already exists, return.
		if chatSessions[chatID] != nil { return nil }
		
		// If the chat ID is in the Moderator blacklist, return.
		if mod.checkBlacklist(chatID: chatID) == true { return nil }
		
		print(">>>>> ADDING NEW SESSION <<<<<")
		
		
		// If we've reached the maximum number of allowed sessions, send them a message if available.
		if chatSessions.count >= maxChatSessions && maxChatSessions != 0 {
			print("ChatSession count reached.  Deferring.")
			//if maxChatSessionsAction != nil { maxChatSessionsAction!(self, chat) }
			return nil
		}
		
		
		// If we're still here, add them.
		if sessionSetupAction == nil { print(TGBotError.EntryMissing.rawValue) ; return nil }
		
		let permissions = mod.getPermissions(chatID: chatID)
		let session = ChatSession(chatID:chatID, data: customData, floodLimit: floodLimit, permissions: permissions, request: { _ in }, event: { _ in })
		session.postInit()
		
		chatSessions[chatID] = session
		
		print("ChatSession added.")
		print("Current Active ChatSessions: ")
		print(chatSessions)
		
		return session
	}
	
	/**
	Attempts to create a user session, as long as one currently doesn't exist.
	*/
	public func createUserSession(user: User, setup: ((UserSession) -> ())?) -> UserSession? {
		
		// Before we create a session, check the user isn't in the Moderator blacklist.
		if mod.checkBlacklist(userID: user.tgID) == true { return nil }
		
		let permissions = mod.getPermissions(chatID: user.tgID)
		let session = UserSession(user: user, floodLimit: floodLimit, permissions: permissions, request: { _ in }, event: { _ in })
		return session
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
		
		for (index, _) in chatSessionActivity.enumerated() {
			if index == chatID {
				chatSessionActivity.removeValue(forKey: chatID)
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
	*/
}
