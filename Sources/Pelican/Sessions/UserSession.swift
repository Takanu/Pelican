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
public class UserSession: Session {
	
	
	//  CORE INTERNAL VARIABLES
	public var bot: Pelican
	/// The user information associated with this session.
	public var info: User
	/// The ID of the user associated with this session.
	public var userID: Int
	/// The chat sessions the user is currently actively occupying.
	public var chatSessions: [ChatSession] = []
	/** A user-defined type assigned by Pelican on creation, used to cleanly associate custom functionality and
	variables to an individual user session.
	*/
	public var data: NSCopying?
	
	
	// DELEGATES / CONTROLLERS
	public var routes = RouteController<UserUpdateType, UserSession, UserUpdate>()
	var permissions: [String] = []
	
	
	// TIME AND ACTIVITY
	public var timeStarted = Date()
	var timeLastActive = Date()
	var timeoutLength: Int {
		get {
			return self.timeoutLength
		}
		
		set(newTimeout) {
			
			// If the new timeout is a usable number, add it to the sessions that need their activity checked.
			if timeoutLength <= 0 && newTimeout > 0 {
				self.timeoutLength = newTimeout
				bot.userSessionActivity[userID] = self
			}
				
				// If the number has been zeroed out, remove it from the activity list.
			else if timeoutLength > 0 && newTimeout <= 0 {
				self.timeoutLength = newTimeout
				bot.userSessionActivity.removeValue(forKey: userID)
			}
		}
	}
	
	
	// Flood Controls
	var floodLimit: FloodLimit     // External flood tracking system.
	
	
	/**
	Initialises a basic user session.
	*/
	init(bot: Pelican, user: User, floodLimit: FloodLimit) {
		self.bot = bot
		self.info = user
		self.userID = user.tgID
		self.floodLimit = floodLimit
	}
	
	public func filterUpdate(update: UserUpdate) {
		
		if update.type == .inlineQuery {
			
			let query = update.data as! InlineQuery
			filterInlineQuery(query: query)
		}
		
		else {
			
			let query = update.data as! ChosenInlineResult
			filterInlineResult(query: query)
		}
	}
	
	
	private func filterInlineQuery(query: InlineQuery) {
		
		// Send a route request
		//_ = routes.routeRequest(content: query, type: .inlineQuery, session: self)
		
		// Check the flood status
		//bumpFlood()
	}
	
	private func filterInlineResult(query: ChosenInlineResult) {
		
		// Send a route request
		//_ = routes.routeRequest(content: query, type: .chosenInlineResult, session: self)
		
		// Check the flood status
		//bumpFlood()
	}
	
	/// Bumps the flood limiter, and potentially blacklists or warns the user.
	func bumpFlood() {
		let limitHit = floodLimit.bump(globalTime: bot.globalTimer)
		if limitHit {
			
			// If we've reached the maximum maximum limit, add this chat ID to the blacklist
			if floodLimit.reachedLimit {
				_ = bot.mod.add(toList: "blacklist", users: self)
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
		
		bot.answerInlineQuery(inlineQueryID: queryID, results: inlineResults, cacheTime: cache, isPersonal: isPersonal, nextOffset: nextOffset, switchPM: switchPM, switchPMParam: switchPMParam)
	}
	
	
	
}
