
import Dispatch     // Linux thing.
import Foundation
import SwiftyJSON

/**
Your own personal pelican for building Telegram bots!

To get started with Pelican, you'll need to place the code below as setup before running the app.
You'll also need to add your API token as a `token` inside `config.json` (create it if you don't have the file),
to assign it to your bot and start receiving updates.  You can get your API token from @BotFather.

## Pelican JSON Contents
```
{
"bot_token": "INSERT:YOUR-KEY-RIGHT-HERE"
"payment_token": "INSERT:PAYMENTS-PLZ-DELICIOUS"
}
```

## Pelican Basic Setup

```
// Create a chat session
class ShinyNewSession: ChatSession {

	override func postInit() {
		// ROUTING
		// Add a basic 'lil route.
		let start = RouteCommand(commands: "start") { update in

			self.requests.async.sendMessage("Ding!", markup: nil, chatID: self.tag.id)

			return true
		}

		// Add some more test routes.
		let taka = RouteCommand(commands: "taka") { update in

			let user = self.requests.sync.getMe()
			let responseMsg = """
			HI!  I AM A \(user?.firstName ?? "null") BOT.
			"""
			self.requests.async.sendMessage(responseMsg, markup: nil, chatID: self.tag.id)

			return true
		}

		// This is a blank route that allows any update given it to automatically pass.
		self.baseRoute = Route(name: "base", action: { update in return false })
		self.baseRoute.addRoutes(start, taka)
	}

}

// Create a bot instance
let pelican = try PelicanBot()

// Add a builder
pelican.addBuilder(SessionBuilder(spawner: Spawn.perChatID(types: nil), idType: .chat, session: ShinyNewSession.self, setup: nil) )

// Configure the bot polling
bot.updateTimeout = 300

// Run it
try pelican.boot()

```
*/
public final class PelicanBot {
	
	// CORE PROPERTIES
	/// The cache system responsible for handling the re-using of already uploaded files and assets, to preserve system resources.
  var cache: CacheManager!
	
	/// A controller that records and manages client connections to Telegram.
	var client: Client
	
	/// The API key assigned to your bot.
	public private(set) var apiKey: String
	
	/// The Payment key assigned to your bot.  To assign the key, add it to the JSON file inside config/pelican.json as "payment_token".
	public private(set) var paymentKey: String?
	
	/// The combination of the API request URL and your API token.
	public private(set) var apiURL: String
	
	
  // CONNECTION SETTINGS
	
	/**
	Identifier of the first update to be returned. Must be greater by one than the highest among the identifiers of previously received updates. By default, updates starting with the earliest unconfirmed update are returned.
	
	An update is considered confirmed as soon as getUpdates is called with an offset higher than its update_id. The negative offset can be specified to retrieve updates starting from -offset update from the end of the updates queue. All previous updates will forgotten.
	
	- warning: Pelican automatically handles this variable, don't use it unless you want to perform something very specific.
	*/
  public var updateOffset: Int = 0
	
	/// The number of messages that can be received in any given update, between 1 and 100.
  public var updateLimit: Int = 100
	
	/// The length of time Pelican will hold onto an update connection with Telegram to wait for updates before disconnecting.
  public var updateTimeout: Int = 300
	
	/// Defines what update types the bot will receive.  Leave empty if all are allowed, or otherwise specify to optimise the bot.
  public var allowedUpdates: [UpdateType] = [.message, .editedMessage, .channelPost, .editedChannelPost, .callbackQuery, .inlineQuery, .chosenInlineResult, .shippingQuery, .preCheckoutQuery]
	
	/// If true, the bot will ignore any historic messages it has received while it has been offline.
  public var ignoreInitialUpdates: Bool = true
	
	/// Whether the bot has started and is running.
  private var started: Bool = false
	
	/// Whether the bot has started and is running.
  public var hasStarted: Bool { return started }
	
	
  // UPDATE QUEUES
	/// The DispatchQueue system that fetches updates and hands them off to any applicable Sessions to handle independently.
	private var updateQueue: LoopQueue?
	
	/// The DispatchQueue system that checks for any scheduled events and hands the ones it finds to the Session that requested them, on the Session queue.
	private var scheduleQueue: LoopQueue?
	
	/// The time the bot started operating.
	var timeStarted: Date?
	
	/// The time the last update the bot has received from Telegram.
	var timeLastUpdate: Date?
	
	/// A pre-built request type to be used for fetching updates.
	var getUpdatesRequest: TelegramRequest {
		let request = TelegramRequest()
		request.method = "getUpdates"
		request.query = [
			"offset": updateOffset,
			"limit": updateLimit,
			"timeout": updateTimeout,
			//"allowed_updates": allowedUpdates.map { $0.rawValue },
		]
		
		return request
	}
	
  // SESSIONS
	/// The set of sessions that are currently active, encapsulated within their respective builders.
  internal var sessions: [SessionBuilder] = []
	
	/// The schedule system for sessions to use to delay the execution of actions.
	public var schedule: Schedule!
	
	
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
		
		let workingDir = PelicanBot.workingDirectory()
		if workingDir == "" {
			throw TGBotError.WorkingDirNotFound
		}
		
		let bundle = Bundle(path: workingDir)
		if bundle == nil {
			throw TGBotError.WorkingDirNotFound
		}
		
		let configURL = bundle?.url(forResource: "config", withExtension: "json", subdirectory: nil)
		if configURL == nil {
			throw TGBotError.ConfigMissing
		}
		
		let data = try Data(contentsOf: configURL!)
		let configJSON = JSON.init(data: data)
    guard let token = configJSON["bot_token"].string else {
      throw TGBotError.KeyMissing
    }
		
		// Set tokens
		self.apiKey = token
		self.apiURL = "https://api.telegram.org/bot" + token
		self.paymentKey = configJSON["payment_token"].string
		
		// Initialise controls and timers
		self.mod = Moderator()
    self.cache = try CacheManager(bundlePath: workingDir)
		self.client = Client(token: token, cache: cache)
		self.schedule = Schedule(workCallback: self.requestSessionWork)
  }
	
  /**
	Starts the bot!
	*/
  public func boot() throws {
		
		// The main thread needs to do 'something', keep this for later
		/**
		// Set the upload queue.
		updateQueue = LoopQueue(queueLabel: "com.pelican.fetchupdates",
														qos: .userInteractive,
														interval: TimeInterval(self.pollInterval)) {
			
			PLog.info("Update Starting...")
			
			let updates = self.requestUpdates()
			if updates != nil {
				self.handleUpdates(updates!)
			}
			
			self.timeLastUpdate = Date()
			PLog.info("Update Complete.")
		}
		*/
		
		// Set the schedule queue.
		scheduleQueue = LoopQueue(queueLabel: "com.pelican.eventschedule",
															qos: .default,
															interval: TimeInterval(1)) {
		
			self.schedule.run()
		}
		
		// Clear the first set of updates if we're asked to.
		if ignoreInitialUpdates == true {
			
			let request = TelegramRequest()
			request.method = "getUpdates"
			request.query = [
				"offset": updateOffset,
				"limit": updateLimit,
				"timeout": 1,
			]
			
			if let response = client.syncRequest(request: request) {
				let update_count = response.result!.array?.count ?? 0
				let update_id = response.result![update_count - 1]["update_id"].int ?? -1
				updateOffset = update_id + 1
			}
			
		}
		
		// Boot!
		self.timeStarted = Date()
		self.timeLastUpdate = Date()
		started = true
		
		//updateQueue!.queueNext()
		scheduleQueue!.queueNext()
		
		print("<<<<< Pelican has started. >>>>>")
		
		// Run the update queue
		while 1 == 1 {
			updateCycle()
		}
		
	}
	
	/**
	The main run loop for Pelican, responsible for fetching and dispatching updates to Sessions.
	*/
	private func updateCycle() {
		PLog.info("Update Starting...")
		
		let updates = self.requestUpdates()
		if updates != nil {
			self.handleUpdates(updates!)
		}
		
		self.timeLastUpdate = Date()
		PLog.info("Update Complete.")
		
	}
  
  /**
	Requests a set of updates from Telegram, based on the poll, offset, updateTimeout and update limit settings
	assigned to Pelican.
	- returns: A `TelegramUpdateSet` if succsessful, or nil if otherwise.
	*/
	public func requestUpdates() -> [Update]? {
		
		var response: TelegramResponse? = nil
		
		// Build a new request with the correct URI and fetch the other data from the Session Request
		PLog.info("Contacting Telegram for Updates...")
		response = client.syncRequest(request: getUpdatesRequest)
		
		// If we have a response, try and build an update list from it.
		if response != nil {
			if response!.status != .ok { return nil }
			let updateResult = self.generateUpdateTypes(response: response!)
			return updateResult
		}
		
		return nil

	}
	
	public func generateUpdateTypes(response: TelegramResponse) -> [Update]? {
		
    // Get the basic result data
		let results = response.result?.array ?? []
    let messageCount = results.count
		
		if response.result == nil { return nil }

    // Make the collection types
		var updates: [Update] = []
		PLog.verbose("Updates Found - \(messageCount)")

    // Iterate through the collected messages
    for i in 0..<messageCount {
      let update_id = response.result![i]["update_id"].int ?? -1
			let responseSlice = response.result![i]

      // This is just a plain old message
      if allowedUpdates.contains(UpdateType.message) {
        if (responseSlice["message"]) != JSON.null {
					
					let update = unwrapIncomingUpdate(json: responseSlice["message"],
																						dataType: Message.self,
																						updateType: .message)
					
					if update != nil {
						updates.append(update!)
					}
        }
      }

      // This is if a message was edited
      if allowedUpdates.contains(UpdateType.editedMessage) {
        if (responseSlice["edited_message"]) != JSON.null {
					let update = unwrapIncomingUpdate(json: responseSlice["edited_message"],
																						dataType: Message.self,
																						updateType: .editedMessage)
					
					if update != nil {
						updates.append(update!)
					}
        }
      }

      // This is for a channel post
      if allowedUpdates.contains(UpdateType.channelPost) {
        if (responseSlice["channel_post"]) != JSON.null {
					let update = unwrapIncomingUpdate(json: responseSlice["channel_post"],
																						dataType: Message.self,
																						updateType: .channelPost)
					
					if update != nil {
						updates.append(update!)
					}
        }
      }

      // This is for an edited channel post
      if allowedUpdates.contains(UpdateType.editedChannelPost) {
        if (responseSlice["edited_channel_post"]) != JSON.null {
					let update = unwrapIncomingUpdate(json: responseSlice["edited_channel_post"],
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
        if (responseSlice["inline_query"]) != JSON.null {
					let update = unwrapIncomingUpdate(json: responseSlice["inline_query"],
																						dataType: InlineQuery.self,
																						updateType: .inlineQuery)
					
					if update != nil {
						updates.append(update!)
					}
        }
      }

      // This type is for when someone has selected an search result from the inline query
      if allowedUpdates.contains(UpdateType.chosenInlineResult) {
        if (responseSlice["chosen_inline_result"]) != JSON.null {
					let update = unwrapIncomingUpdate(json: responseSlice["chosen_inline_result"],
																						dataType: ChosenInlineResult.self,
																						updateType: .chosenInlineResult)
					
					if update != nil {
						updates.append(update!)
					}
        }
      }

      /// Callback Query handling (receiving button presses for inline buttons with callback data)
      if allowedUpdates.contains(UpdateType.callbackQuery) {
        if (responseSlice["callback_query"]) != JSON.null {
					let update = unwrapIncomingUpdate(json: responseSlice["callback_query"],
																						dataType: CallbackQuery.self,
																						updateType: .callbackQuery)
					
					if update != nil {
						updates.append(update!)
					}
        }
      }

      updateOffset = update_id + 1
    }

    return updates
  }
	
	/**
	Attempts to unwrap a slice of the response to the desired type, returning it as an Update.
	*/
	internal func unwrapIncomingUpdate<T: UpdateModel>(json: JSON, dataType: T.Type, updateType: UpdateType) -> Update? {
		
		// Setup the decoder
		let decoder = JSONDecoder()
		
		// Attempt to decode
		do {
			let data = try json.rawData()
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
		
		// Update the last active time.
		timeLastUpdate = Date()
		PLog.info("Updates handled.")
		
  }
	
	
	/**
	Adds a new builder to the bot, enabling the automated creation and filtering of updates to your defined Session types.
	*/
	public func addBuilder(_ builders: SessionBuilder...) {
		
		for builder in builders {
			sessions.append(builder)
		}
	}
}
