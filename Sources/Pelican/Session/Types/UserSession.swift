//
//  UserChatSession.swift
//  party
//
//  Created by Takanu Kyriako on 26/06/2017.
//
//

import Foundation
import Vapor

/**
A high-level class for managing states and information for each user that attempts to interact with your bot
(and that isn't immediately blocked by the bot's blacklist).  Features embedded permission lists populated by Moderator,
the chat sessions the user is actively participating in and other key pieces of information.

UserSession is also used to handle InlineQuery and ChosenInlineResult routes, as only UserSessions will receive inline updates.
*/
open class UserSession: Session {
	
	
	//  CORE INTERNAL VARIABLES
	public var tag: SessionTag
	
	
	/// The user information associated with this session.
	public var info: User
	/// The ID of the user associated with this session.
	public var userID: Int
	/// The chat sessions the user is currently actively occupying.
	public var chatSessions: [ChatSession] = []
	/** A user-defined type assigned by Pelican on creation, used to cleanly associate custom functionality and
	variables to an individual user session.
	*/
	
	// API REQUESTS
	// Shortcuts for API requests.
	public var answer: TGAnswer
	
	// DELEGATES / CONTROLLERS
	
	/// Handles and matches user requests to available bot functions.
	public var routes: RouteController
	
	/// Stores what Moderator-controlled permissions the User Session has.
	public var mod: SessionModerator
	
	/// Stores a link to the schedule, that allows events to be executed at a later date.
	public var schedule: Schedule
	
	
	// TIME AND ACTIVITY
	public var timeStarted = Date()
	public var timeLastActive = Date()
	public var timeoutLength: Int = 0
	
	
	public required init(bot: Pelican, tag: SessionTag, update: Update) {
		
		self.tag = tag
		
		self.info = update.from!
		self.userID = update.from!.tgID
		self.routes = RouteController()
		self.mod = SessionModerator(tag: tag, moderator: bot.mod)!
		self.schedule = bot.schedule
		
		self.answer = TGAnswer(tag: tag)
	}
	
	
	open func postInit() {
		
	}
	
	
	open func close() {
		
	}
	
	
	public func update(_ update: Update) {
		
		// This needs revising, whatever...
		_ = routes.handle(update: update)
		
	}
}
