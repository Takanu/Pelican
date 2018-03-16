
import Dispatch     // Linux thing.
import Foundation



/**
Your own personal pelican for building Telegram bots!

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
public final class Pelican {
	
	// CORE PROPERTIES
	/// The cache system responsible for handling the re-using of already uploaded files and assets, to preserve system resources.
  var cache: CacheManager
	
	/// The API key assigned to your bot.  PLEASE DO NOT ASSIGN IT HERE, ADD IT TO A JSON FILE INSIDE config/pelican.json as a "token".
  var apiKey: String
	
	/// The Payment key assigned to your bot.  To assign the key, add it to the JSON file inside config/pelican.json as "payment_token".
	var paymentKey: String?
	
	/// The combination of the API request URL and your API token.
  var apiURL: String
	
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
	
	/// (Polling) The length of time Pelican will hold onto an update connection with Telegram to wait for updates before disconnecting.
  public var timeout: Int = 1
	
	/// Defines what update types the bot will receive.  Leave empty if all are allowed, or otherwise specify to optimise the bot.
  public var allowedUpdates: [UpdateType] = []
	
	/// If true, the bot will ignore any historic messages it has received while it has been offline.
  public var ignoreInitialUpdates: Bool = true
	
	/// Whether the bot has started and is running.
  private var started: Bool = false
	
	/// Whether the bot has started and is running.
  public var hasStarted: Bool { return started }
	
	
  // QUEUES
	/// The time the bot started operating.
	var timeStarted: Date
	
	/// The time the last update the bot has received from Telegram.
	var timeLastUpdate: Date
	
  fileprivate var updateQueue: UpdateFetchQueue?
  var uploadQueue: DispatchQueue
  var pollInterval: Int = 0
  var globalTimer: Int = 0        // Used for executing scheduled events.
  public var getTime: Int { return globalTimer }
	
	
  // SESSIONS
	/// The set of sessions that are currently active, encapsulated within their respective builders.
  internal var sessions: [SessionBuilder] = []
	
	/// The schedule system for sessions to use to delay the execution of actions.
	public var schedule = Schedule()
	
	
  // MODERATION
	/// The moderator system, used for blacklisting and whitelisting users and chats to either prevent or allow them to use the bot.
	public var mod: Moderator
	
	// DEBUG
	// ???
	
	
  /**
	Initialises Pelican.
	- warning: Pelican will attempt to find your API key at this point, and will fail if it's missing.
	*/
  public init() throws {
		
		// Obtain the token from pelican.json
    guard let token = config["pelican", "token"]?.string else {
      throw TGBotError.KeyMissing
    }
		
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
  }
	
  /// Perform correct droplet configuration here.
  public func boot() {
		
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

	
	/**
	Sets the frequency at which the bot looks for updates from users to act on.  If a timeout is set,
	this becomes the length of time it takes after handling a set of updates to request more from Telegram,
	until the timeout amount is reached.
	*/
  public func setPollingInterval(_ interval: Int) {
		updateQueue = UpdateFetchQueue(interval: TimeInterval(interval)) {
			
			PLog.info("Update Starting...")
			
      let updates = self.requestUpdates()
			if updates != nil { self.handleUpdates(updates!) }
			self.updateQueue!.queueNext()
			
			PLog.info("Update Complete.")
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
		PLog.info("Contacting Telegram for Updates...")
		
		var response: Response? = nil
		let vaporRequest = Request(method: .post, uri: apiURL + "/getUpdates")
		//print(vaporRequest)
		
		do {
			// Build a new request with the correct URI and fetch the other data from the Session Request
			vaporRequest.query = try query.makeNode(in: nil)
			//vaporRequest.headers = [HeaderKey.connection: "keep-alive"]
			
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
			let responseSlice = response["result", i]!

      // This is just a plain old message
      if allowedUpdates.contains(UpdateType.message) {
        if (responseSlice["message"]) != nil {
					
					let update = unwrapIncomingUpdate(json: responseSlice["message"]!,
																						dataType: Message.self,
																						updateType: .message)
					
					if update != nil {
						updates.append(update!)
					}
        }
      }

      // This is if a message was edited
      if allowedUpdates.contains(UpdateType.editedMessage) {
        if (responseSlice["edited_message"]) != nil {
					let update = unwrapIncomingUpdate(json: responseSlice["edited_message"]!,
																						dataType: Message.self,
																						updateType: .editedMessage)
					
					if update != nil {
						updates.append(update!)
					}
        }
      }

      // This is for a channel post
      if allowedUpdates.contains(UpdateType.channelPost) {
        if (responseSlice["channel_post"]) != nil {
					let update = unwrapIncomingUpdate(json: responseSlice["channel_post"]!,
																						dataType: Message.self,
																						updateType: .channelPost)
					
					if update != nil {
						updates.append(update!)
					}
        }
      }

      // This is for an edited channel post
      if allowedUpdates.contains(UpdateType.editedChannelPost) {
        if (responseSlice["edited_channel_post"]) != nil {
					let update = unwrapIncomingUpdate(json: responseSlice["edited_channel_post"]!,
																						dataType: Message.self,
																						updateType: .editedChannelPost)
					
					if update != nil {
						updates.append(update!)
					}
        }
      }

      // COME BACK TO THESE LATER
      // This type is for when someone tries to search something in the message box for this bot
      if allowedUpdates.contains(UpdateType.inlineQuery) {
        if (responseSlice["inline_query"]) != nil {
					let update = unwrapIncomingUpdate(json: responseSlice["inline_query"]!,
																						dataType: InlineQuery.self,
																						updateType: .inlineQuery)
					
					if update != nil {
						updates.append(update!)
					}
        }
      }

      // This type is for when someone has selected an search result from the inline query
      if allowedUpdates.contains(UpdateType.chosenInlineResult) {
        if (responseSlice["chosen_inline_result"]) != nil {
					let update = unwrapIncomingUpdate(json: responseSlice["chosen_inline_result"]!,
																						dataType: ChosenInlineResult.self,
																						updateType: .chosenInlineResult)
					
					if update != nil {
						updates.append(update!)
					}
        }
      }

      /// Callback Query handling (receiving button presses for inline buttons with callback data)
      if allowedUpdates.contains(UpdateType.callbackQuery) {
        if (response["result", i, "callback_query"]) != nil {
					let update = unwrapIncomingUpdate(json: responseSlice["callback_query"]!,
																						dataType: CallbackQuery.self,
																						updateType: .callbackQuery)
					
					if update != nil {
						updates.append(update!)
					}
        }
      }

      offset = update_id + 1
    }

    return updates
  }
	
	/**
	Attempts to unwrap a slice of the response to the desired type, returning it as an Update.
	*/
	internal func unwrapIncomingUpdate<T: UpdateModel>(json: JSON, dataType: T.Type, updateType: UpdateType) -> Update? {
		
		// Setup the decoder
		let data = Data.init(bytes: try! json.makeBytes().array)
		let decoder = JSONDecoder()
		
		// Attempt to decode
		do {
			let result = try decoder.decode(dataType, from: data)
			let update = Update(withData: result, json: json, type: updateType)
			
			// Check that the update isn't on any blacklists.
			if update.chat != nil {
				if mod.checkBlacklist(chatID: update.chat!.tgID) == true {
					return nil
				}
			}
			
			if update.from != nil {
				if mod.checkBlacklist(chatID: update.from!.tgID) == true {
					return nil
				}
			}
			
			// Now we can return
			return update
			
			
		} catch {
			PLog.error("Pelican Error (Decoding message from updates) - \n\n\(error)\n")
			return nil
		}
	}
	
  /**
	Used by the in-built long polling solution to match updates to sessions.
	### EDIT/REMOVE IN UPCOMING REFACTOR
	*/
	internal func handleUpdates(_ updates: [Update]) {
		
    // Check the global timer for any scheduled events
    globalTimer += pollInterval
    //checkChatSessionQueues()
		PLog.info("Handling updates...")
		
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
		PLog.info("Updates handled.")
		
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
