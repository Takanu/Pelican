//
//  UserSession.swift
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
	public private(set) var tag: SessionTag
	public private(set) var dispatchQueue: SessionDispatchQueue
	
	/// The user information associated with this session.
	public private(set) var info: User
	
	/// The ID of the user associated with this session.
	public private(set) var userID: String
	
	/// The chat sessions this user is currently actively occupying.
	/// -- Not currently functional, undecided if it will be implemented
	//public var chatSessions: [SessionTag] = []

	
	// API REQUESTS
	// Shortcuts for API requests.
	public private(set) var requests: MethodRequest
	
	
	// DELEGATES / CONTROLLERS
	/// Delegate for creating, modifying and getting other Sessions.
	public private(set) var sessions: SessionRequest
	
	/// Handles and matches user requests to available bot functions.
	public var baseRoute: Route
	
	/// Stores what Moderator-controlled permissions the User Session has.
	public private(set) var mod: SessionModerator
	
	/// Handles timeout conditions.
	public private(set) var timeout: TimeoutMonitor
	
	/// Handles flood conditions.
	public private(set) var flood: FloodMonitor
	
	/// Stores a link to the schedule, that allows events to be executed at a later date.
	public private(set) var schedule: Schedule
	
	/// Pre-checks and filters unnecessary updates.
	public private(set) var filter: UpdateFilter
	
	
	// TIME AND ACTIVITY
	public private(set) var timeStarted = Date()
	
	
	public required init?(bot: PelicanBot, tag: SessionTag) {
		
		if tag.user == nil { return nil }
		
		self.tag = tag
		
		self.info = tag.user!
		self.userID = tag.user!.tgID
		self.sessions = SessionRequest(bot: bot)
		self.baseRoute = Route(name: "base", routes: [])
		
		self.mod = SessionModerator(tag: tag, moderator: bot.mod)!
		self.timeout = TimeoutMonitor(tag: tag, schedule: bot.schedule)
		self.flood = FloodMonitor()
		self.filter = UpdateFilter()
		
		self.schedule = bot.schedule
		
		self.requests = MethodRequest(tag: tag)
		self.dispatchQueue = SessionDispatchQueue(tag: tag, label: "com.pelican.usersession_\(tag.sessionID)",qos: .userInitiated)
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
