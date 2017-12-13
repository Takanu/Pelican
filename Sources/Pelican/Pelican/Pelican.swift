
import Dispatch     // Linux thing.
import Foundation
import Vapor
import FluentProvider
import HTTP
import FormData
import Multipart
import TLS

protocol TelegramParameter: NodeConvertible, JSONConvertible {
  func getQueryParameter() -> String
}

/** Required for classes that wish to receive message objects once the upload is complete.
*/
public protocol ReceiveUpload {
	func receiveMessage(message: Message)
}

// The Dispatch queue for getting updates and serving them to sessions.
private class UpdateQueue {
  private let queue = DispatchQueue(label: "TG-Updates",
                                    qos: .userInteractive,
                                    target: nil)
  
  private let interval: TimeInterval
	private var startTime: Date
	private var lastExecuteLength: TimeInterval
  private let execute: () -> Void
  private var operation: DispatchWorkItem?
  
	init(interval: TimeInterval, execute: @escaping () -> Void) {
    self.interval = interval
		self.startTime = Date()
		self.lastExecuteLength = TimeInterval.init(0)
    self.execute = execute
		self.operation = DispatchWorkItem(qos: .userInteractive, flags: .enforceQoS) { [weak self] in
			
			// Record the starting time and execute the loop
			self?.startTime = Date()
			self?.execute()
		}
  }
	
	func queueNext() {
		lastExecuteLength = abs(startTime.timeIntervalSinceNow)
		
		// Account for loop time in the asynchronous delay.
		let delayTime = interval - lastExecuteLength
		
		// If the delay time left is below 0, execute the loop immediately.
		if delayTime <= 0 {
			PLog.verbose("Update loop executing immediately.")
			queue.async(execute: self.operation!)
		}
			
		// Otherwise use the built delay time.
		else {
			PLog.verbose("Update loop executing at \(DispatchWallTime.now() + delayTime)")
			queue.asyncAfter(wallDeadline: .now() + delayTime, execute: self.operation!)
		}
	}
  
  func stop() {
    operation?.cancel()
		PLog.warning("Update cycle cancelled")
  }
}

/**
Defines the kind of action you wish a chat action to specify.  (This description sucks).

- note: Should be moved to Types+Standard
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
Motherfucking Vapor.
*/
enum TGVaporError: String, Error {
	case EngineSucks = "Engine is unable to keep an SSL connection going, please use \"foundation\" instead, under your droplet configuration file."
}

/** 
A deprecated internal type used to enable models to switch between node-type conversion for response purposes, 
and that for databasing purposes.
*/
public enum TGContext: Vapor.Context {
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
	/// The cache system responsible for handling the re-using of already uploaded files and assets, to preserve system resources.
  var cache: CacheManager
	/// The API key assigned to your bot.  PLEASE DO NOT ASSIGN IT HERE, ADD IT TO A JSON FILE INSIDE config/pelican.json as a "token".
  var apiKey: String
	/// The combination of the API request URL and your API token.
  var apiURL: String
	/// The droplet powering the server
	var drop: Droplet?
	/// Client Connection with Vapor, to Telegram.
	var client: ClientProtocol?
	/// The type of client being used by the app
	var clientType: String = ""
	/// The TLS context being used?
	var context: TLS.Context? = nil
	/// Defines an object to be used for custom data, to be used purely for cloning into newly-created ChatSessions.  DO NOT EDIT CONTENTS.
  private var customData: NSCopying?
	
	
	/// Returns the API key assigned to your bot.
	public var getAPIKey: String { return apiKey }
	/// Returns the combination of the API request URL and your API token.
	public var getAPIURL: String { return apiURL }
	
	
  // CONNECTION SETTINGS
	/**
	(Polling) Identifier of the first update to be returned. Must be greater by one than the highest among the identifiers of previously received updates. By default, updates starting with the earliest unconfirmed update are returned.
	
	An update is considered confirmed as soon as getUpdates is called with an offset higher than its update_id. The negative offset can be specified to retrieve updates starting from -offset update from the end of the updates queue. All previous updates will forgotten.
	
	- warning: Pelican automatically handles this variable, don't use it unless you want to perform something very specific.
	*/
  public var offset: Int = 0
	/// (Polling) The number of messages that can be received in any given update, between 1 and 100.
  public var limit: Int = 100
	// (Polling) The length of time Pelican will hold onto an update connection with Telegram to wait for updates before disconnecting.
  public var timeout: Int = 1
	
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
  internal var sessions: [SessionBuilder] = []
	/// The schedule system for sessions to use to delay the execution of actions.
	public var schedule = Schedule()
	
	
  // MODERATION
	/// The moderator system, used for blacklisting and whitelisting users and chats to either prevent or allow them to use the bot.
	public var mod: Moderator
	
	// DEBUG
	// ???
	
	
	// Boots the provider?
	public func boot(_ config: Vapor.Config) throws {
		print("*shrug")
	}
	
	
  // Provider conforming functions
  public init(config: Vapor.Config) throws {
		
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
		
		// Fake-initialise the client
		//try! cache.setBundlePath(Droplet().config.publicDir)
		
		// Ensure that the Foundation Engine is being used.
		
		let engine = config["droplet", "client"]?.string ?? ""
		if engine == "foundation" {
			self.clientType = "foundation"
			//print("Hey, sorry but you'll need to use the Foundation Client instead of the Engine Client.  I've tried being friends with it but it's just too stubborn.  Ill remove this once the Engine Client starts working with it <3")
			//throw TGVaporError.EngineSucks
		}
		else {
			self.clientType = "engine"
		}
  }
	
	
  public func afterInit(_ drop: Droplet) { }
	
	/// Occurs "just" before the drop is run itself, after drop.run() is called.
  public func beforeRun(_ drop: Droplet) {
		
    if ignoreInitialUpdates == true {
      _ = self.requestUpdates()
    }
    
    if allowedUpdates.count == 0 {
      for type in iterateEnum(UpdateType.self) {
        allowedUpdates.append(type)
      }
    }
		
		started = true
		updateQueue!.queueNext()
  }
	
  /// Perform correct droplet configuration here.
  public func boot(_ drop: Droplet) {
		
		// Get the config
		let config = drop.config
		try! config.resolveClient()  // idk what this does...
		context = try! TLS.Context(.client)
		self.drop = drop
		
		// Setup the client used to send and get requests.
		let engine = config["droplet", "client"]?.string ?? ""
		if engine == "foundation" {
			self.client = try! drop.client.makeClient(hostname: "api.telegram.org", port: 443, securityLayer: .tls(context!), proxy: .none)
			//self.client = try! drop.client.make
		}
		
		else {
			self.client = try! drop.client.makeClient(hostname: "api.telegram.org", port: 443, securityLayer: .tls(context!), proxy: .none)
		}
		
		// Setup the logger.
		PLog.console = drop.log
		
		// Setup the cache
		try! cache.setBundlePath(drop.config.workDir + "/Public")
	}

	
	/**
	Sets the frequency at which the bot looks for updates from users to act on.  If a timeout is set,
	this becomes the length of time it takes after handling a set of updates to request more from Telegram,
	until the timeout amount is reached.
	*/
  public func setPoll(interval: Int) {
		updateQueue = UpdateQueue(interval: TimeInterval(interval)) {
			
			PLog.verbose("Update Starting...")
			
      let updates = self.requestUpdates()
			if updates != nil { self.filterUpdates(updates: updates!) }
			self.updateQueue!.queueNext()
			
			PLog.verbose("Update Complete.")
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
	- returns: A `TelegramUpdateSet` if succsessful, or nil if otherwise.
	*/
	public func requestUpdates() -> [Update]? {
		
		//print("UPDATE START")
		
    let query = makeUpdateQuery()
		PLog.verbose("Contacting Telegram for Updates...")
		
		var response: Response? = nil
		let vaporRequest = Request(method: .post, uri: apiURL + "/getUpdates")
		//print(vaporRequest)
		
		do {
			// Build a new request with the correct URI and fetch the other data from the Session Request
			vaporRequest.query = try query.makeNode(in: nil)
			vaporRequest.headers = [HeaderKey.connection: "keep-alive"]
			
			response = connectToClient(request: vaporRequest, attempts: 0)
			
		} catch {
			print(error)
			print(TGReqError.NoResponse.rawValue)
			return nil
		}
		
		//print(response)
		
		// If we have a response, try and build an update list from it.
		if response != nil {
			if response!.status != .ok { return nil }
			
			//print(response)
			
			let updateResult = self.filterUpdateResponse(response: response!.json!)
			if updateResult != nil {
				return updateResult
			}
		}
		
		return nil

	}
	
	public func filterUpdateResponse(response: JSON) -> [Update]? {
		
    // Get the basic result data
		let results = response["result"]?.array ?? []
    let messageCount = results.count

    // Make the collection types
		var updates: [Update] = []
		PLog.verbose("Updates Found - \(messageCount)")

    // Iterate through the collected messages
    for i in 0..<messageCount {
      let update_id = response["result", i, "update_id"]?.int ?? -1


      // This is just a plain old message
      if allowedUpdates.contains(UpdateType.message) {
        if (response["result", i, "message"]) != nil {

					// Find and build a node based on the search.
					guard let messageNode = response.makeNode(in: nil)["result", i, "message"] else {
            //drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
            offset = update_id + 1
            continue
          }

					guard let message = try? Message(row: Row(messageNode)) else {
            //drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
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
        if (response["result", i, "inline_query"]) != nil {
          guard let messageNode = response.makeNode(in: nil)["result", i, "inline_query"] else {
            //drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
						//print("inline_query")
            offset = update_id + 1
            continue
          }

					guard let message = try? InlineQuery(row: Row(messageNode)) else {
						//drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
						//print("inline_query")
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
        if (response["result", i, "chosen_inline_result"]) != nil {
          guard let messageNode = response.makeNode(in: nil)["result", i, "chosen_inline_result"] else {
            //drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
						//print("Chosen Inline Result")
            offset = update_id + 1
            continue
          }

					guard let message = try? ChosenInlineResult(row: Row(messageNode)) else {
						//drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
						//print("Chosen Inline Result")
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
        if (response["result", i, "callback_query"]) != nil {
          guard let messageNode = response.makeNode(in: nil)["result", i, "callback_query"] else {
            //drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
						//print("Callback Query")
            offset = update_id + 1
            continue
          }

					guard let message = try? CallbackQuery(row: Row(messageNode)) else {
						//drop.console.error(TGUpdateError.BadUpdate.rawValue, newLine: true)
						//print("Callback Query")
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
	internal func filterUpdates(updates: [Update]) {
		
    // Check the global timer for any scheduled events
    globalTimer += pollInterval
    //checkChatSessionQueues()
		PLog.verbose("Handling updates...")
		
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
						
						if response == .include || response == .all {
							let session = capture.getSession(bot: self, update: update)!
							update.linkedSessions.append(session)
						}
						
						if response == .execute || response == .all {
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
		PLog.verbose("Updates handled.")
		
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
