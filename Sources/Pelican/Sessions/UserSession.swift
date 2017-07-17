//
//  UserChatSession.swift
//  party
//
//  Created by Ido Constantine on 26/06/2017.
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
	public var builderID: Int
	
	
	/// The user information associated with this session.
	public var info: User
	/// The ID of the user associated with this session.
	public var userID: Int
	/// The chat sessions the user is currently actively occupying.
	public var chatSessions: [ChatSession] = []
	/** A user-defined type assigned by Pelican on creation, used to cleanly associate custom functionality and
	variables to an individual user session.
	*/
	
	
	// DELEGATES / CONTROLLERS
	
	/// Handles and matches user requests to available bot functions.
	public var routes: RouteController
	
	public var permissions: Permissions
	
	
	// TIME AND ACTIVITY
	public var timeStarted = Date()
	public var timeLastActive = Date()
	public var timeoutLength: Int = 0
	
	
	// CALLBACKS
	public var sendRequest: (TelegramRequest) -> (TelegramResponse)
	public var sendEvent: (SessionEvent) -> ()
	
	
	// Flood Controls
	//var floodLimit: FloodLimit     // External flood tracking system.
	
	
	public required init(bot: Pelican, builder: SessionBuilder, update: Update) {
		
		self.builderID = builder.getID
		
		self.info = update.from!
		self.userID = update.from!.tgID
		//self.floodLimit = floodLimit
		self.permissions = bot.mod.getPermissions(userID: self.userID)
		self.routes = RouteController()
		
		self.sendRequest = bot.sendRequest(_:)
		self.sendEvent = bot.sendEvent(_:)
	}
	
	public func postInit() {
		
	}
	
	
	public func update(_ update: Update) {
		
		// This needs revising, whatever...
		let handled = routes.routeRequest(update: update, type: update.type, session: self)
		
	}
	
	/*
	/// Bumps the flood limiter, and potentially blacklists or warns the user.
	func bumpFlood() {
		let limitHit = floodLimit.bump(globalTime: bot.globalTimer)
		if limitHit {
			
			// If we've reached the maximum maximum limit, add this chat ID to the blacklist
			if floodLimit.reachedLimit {
				//_ = bot.mod.add(toList: "blacklist", users: self)
				//bot.blacklistChatSession(session: self)
				return
			}
			
			// Otherwise if set, send the user a warning
			if bot.floodLimitWarning != nil {
				bot.floodLimitWarning!(self)
			}
		}
	}

	
	/**
	Responds to an inline query with an array of results.
	*/
	public func sendInlineResults(_ inlineResults: [InlineResult], queryID: String, cache: Int = 300, isPersonal: Bool = false, nextOffset: Int = 0, switchPM: String = "", switchPMParam: String = "") {
		
		let request = TelegramRequest.answerInlineQuery(inlineQueryID: queryID, results: inlineResults, cacheTime: cache, isPersonal: isPersonal, nextOffset: nextOffset, switchPM: switchPM, switchPMParam: switchPMParam)
		sendRequest(request)
	}
	*/
}
