//
//  UserChatSession.swift
//  party
//
//  Created by Takanu Kyriako on 26/06/2017.
//
//

import Foundation

/**
A high-level class for managing states and information for each user that attempts to interact with your bot
(and that isn't immediately blocked by the bot's blacklist).

UserSession is also used to handle InlineQuery and ChosenInlineResult routes, as ChatSessions cannot receive inline updates.
*/
open class UserSession: Session {
	
	//  CORE INTERNAL VARIABLES
	public var tag: SessionTag
	public var dispatchQueue: SessionDispatchQueue
	
	/// The user information associated with this session.
	public var info: User
	
	/// The ID of the user associated with this session.
	public var userID: Int
	
	/// The chat sessions this user is currently actively occupying.
	/// -- Not currently functional, undecided if it will be implemented
	//public var chatSessions: [SessionTag] = []

	
	// API REQUESTS
	// Shortcuts for API requests.
	public var requests: SessionRequest
	
	
	// DELEGATES / CONTROLLERS
	/// Handles and matches user requests to available bot functions.
	public var baseRoute: Route
	
	/// Stores what Moderator-controlled permissions the User Session has.
	public var mod: SessionModerator
	
	/// Handles timeout conditions.
	public var timeout: TimeoutMonitor
	
	/// Handles flood conditions.
	public var flood: FloodMonitor
	
	/// Stores a link to the schedule, that allows events to be executed at a later date.
	public var schedule: Schedule
	
	/// Pre-checks and filters unnecessary updates.
	public var filter: UpdateFilter
	
	
	// TIME AND ACTIVITY
	public var timeStarted = Date()
	public var timeLastActive = Date()
	public var timeoutLength: Int = 0
	
	
	public required init(bot: PelicanBot, tag: SessionTag, update: Update) {
		
		self.tag = tag
		
		self.info = update.from!
		self.userID = update.from!.tgID
		self.baseRoute = Route(name: "base", routes: [])
		
		self.mod = SessionModerator(tag: tag, moderator: bot.mod)!
		self.timeout = TimeoutMonitor(tag: tag, schedule: bot.schedule)
		self.flood = FloodMonitor()
		self.filter = UpdateFilter()
		
		self.schedule = bot.schedule
		
		self.requests = SessionRequest(tag: tag)
		self.dispatchQueue = SessionDispatchQueue(tag: tag, label: "com.pelican.usersession",qos: .userInitiated)
	}
	
	
	open func postInit() {
		
	}
	
	open func cleanup() {
		self.baseRoute.close()
		self.timeout.close()
		self.flood.clearAll()
		self.dispatchQueue.cancelAll()
		self.filter.reset()
	}
	
	
	public func update(_ update: Update) {
		
		if filter.verifyUpdate(update) == false {
			self.timeout.bump(update)
			self.flood.handle(update)
			return
			
		}
		
		dispatchQueue.async {
			
			// Bump the timeout controller first so if flood or another process closes the Session, a new timeout event will not be added.
			self.timeout.bump(update)
			
			// This needs revising, whatever...
			_ = self.baseRoute.handle(update)
			
			// Bump the flood controller after
			self.flood.handle(update)
		}
		
		
	}
}
