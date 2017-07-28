
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
// Make sure you set up Pelican manually so you can assign it variables.
let config = try Config()
let pelican = try Pelican(config: config)


// Add Builder
pelican.addBuilder(SessionBuilder(spawner: Spawn.perChatID(types: nil), idType: .chat, session: TestUser.self, setup: nil) )

// Add the provider and run it!
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
		
		//print("UPDATE START")
		
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
					
					// Check that the update should be used before adding it.
					if mod.checkBlacklist(chatID: message.chat.tgID) == false {
						if mod.checkBlacklist(userID: message.from!.tgID) == false {
							updates.append(Update(withData: message as UpdateModel, node: messageNode))
						}
					}
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
					
					// Check that the update should be used before adding it.
					if mod.checkBlacklist(userID: message.from.tgID) == false {
						updates.append(Update(withData: message as UpdateModel, node: messageNode))
					}
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
					
					// Check that the update should be used before adding it.
					if mod.checkBlacklist(userID: message.from.tgID) == false {
						updates.append(Update(withData: message as UpdateModel, node: messageNode))
					}
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
					
					// Check that the update should be used before adding it.
					if mod.checkBlacklist(userID: message.from.tgID) == false {
						updates.append(Update(withData: message as UpdateModel, node: messageNode))
					}
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
		
    //print("START FILTER")
		
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
		
		//print(updates)
		
		
		// Check the schedule.
		schedule.run()
		
		
		// Update the last active time.
		timeLastUpdate = Date()
		//print("UPDATE END")
		
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
		
		switch event.action {
			
		// In this event, the session just needs removing without any other tasks.
		case .remove:
			sessions.forEach( { $0.removeSession(tag: event.tag) } )
			
		
		// In a blacklist event, first make sure the Session ID type matches.  If not, return.
		case .blacklist:
			
			switch event.tag.getSessionIDType {
				
			case .chat:
				mod.addToBlacklist(chatIDs: event.tag.getSessionID)
			case .user:
				mod.addToBlacklist(userIDs: event.tag.getSessionID)
			default:
				return
			}
			
			sessions.forEach( { $0.removeSession(tag: event.tag) } )
			
		}
		
		
	}
	
	
	/**
	Adds a new builder to the bot, enabling the automated creation and filtering of updates to your defined Session types.
	*/
	public func addBuilder(_ builder: SessionBuilder) {
		
		// Create a generator for the Builder ID and cycle through until we can make sure it's unique
		var generator = Xoroshiro()
		
		var id = 0
		while id == 0 || sessions.contains(where: {$0.getID == id}) == true {
			id = Int(generator.random32())
		}
		
		// Set the ID and add the builder
		builder.setID(id)
		sessions.append(builder)
	}
}
