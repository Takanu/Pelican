//
//  SessionModerator.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 26/07/2017.
//
//

import Foundation
import Vapor

/**
Contains the permissions associated with a single user or chat.  A SessionModerator can only be 
applied to a Chat or User, as every other ID lacks any kind of persistence to be useful for
moderation purposes.  (Don't do it, please).
*/
public class SessionModerator {
	
	/// The session the moderator is delegating for, as identified by it's tag.
	private var tag: SessionTag
	
	private var changeTitleCallback: (SessionIDType, String, [Int], Bool) -> ()
	private var checkTitleCallback: (Int, SessionIDType) -> ([String])
	
	public var getID: Int { return tag.id }
	public var getTitles: [String] { return checkTitleCallback(tag.id, tag.idType) }
	
	
	/**
	Attempts to create a SessionModerator.
	- warning: This should not be used under any circumstances if your session does not represent a User or Chat session, and 
	if the SessionBuilder used to create is is not using User or Chat IDs respectively.  🙏
	*/
	init?(tag: SessionTag, moderator: Moderator) {
		
		self.tag = tag
		
		self.changeTitleCallback = moderator.switchTitle
		self.checkTitleCallback = moderator.getTitles
		
		if tag.idType != .chat || tag.idType != .user { return }
	}
	
	/**
	Adds a title to this session.
	*/
	public func add(_ title: String) {
		
		changeTitleCallback(tag.idType, title, [tag.id], false)
	}
	
	/**
	Adds a title to the IDs of the users specified.
	*/
	public func addToUsers(title: String, users: User...) {
		
		changeTitleCallback(.user, title, users.map({$0.tgID}), false)
	}
	
	/**
	Adds a title to the IDs of the chats specified.
	*/
	public func addToChats(title: String, chats: Chat...) {
		
		changeTitleCallback(.chat, title, chats.map({$0.tgID}), false)
	}
	
	/**
	Removes a title from this session, if associated with it.
	*/
	public func remove(_ title: String) {
		
		changeTitleCallback(tag.idType, title, [tag.id], true)
	}
	
	/**
	Adds a title to the IDs of the users specified.
	*/
	public func removeFromUsers(title: String, users: User...) {
		
		changeTitleCallback(.user, title, users.map({$0.tgID}), true)
	}
	
	/**
	Adds a title to the IDs of the chats specified.
	*/
	public func removeFromChats(title: String, chats: Chat...) {
		
		changeTitleCallback(.chat, title, chats.map({$0.tgID}), true)
	}
	
	/**
	Checks to see whether a User has the specified title.
	- returns: True if it does, false if not.
	*/
	public func getTitles(forUser user: User) -> [String] {
		
		return checkTitleCallback(user.tgID, .user)
	}
	
	/**
	Checks to see whether a Chat has the specified title.
	- returns: True if it does, false if not.
	*/
	public func getTitles(forChat chat: Chat) -> [String] {
		
		return checkTitleCallback(chat.tgID, .chat)
	}
	
	/**
	Checks to see whether this Session has a given title.
	- returns: True if it does, false if not.
	*/
	public func checkTitle(_ title: String) -> Bool {
		
		let titles = checkTitleCallback(tag.id, tag.idType)
		if titles.contains(title) { return true }
		return false
	}
	
	/**
	Checks to see whether a User has the specified title.
	- returns: True if it does, false if not.
	*/
	public func checkTitle(forUser user: User, title: String) -> Bool {
		
		let titles = checkTitleCallback(user.tgID, .user)
		if titles.contains(title) { return true }
		return false
	}
	
	/**
	Checks to see whether a Chat has the specified title.
	- returns: True if it does, false if not.
	*/
	public func checkTitle(forChat chat: Chat, title: String) -> Bool {
		
		let titles = checkTitleCallback(chat.tgID, .chat)
		if titles.contains(title) { return true }
		return false
	}
	
	/**
	Removes all titles associated with this session ID.
	*/
	public func clearTitles() {
		
		let titles = checkTitleCallback(tag.id, tag.idType)
		
		for title in titles {
			changeTitleCallback(tag.idType, title, [tag.id], true)
		}
	}
	
	/**
	Blacklists the Session ID, which closes the Session and any associated ScheduleEvents, and adds the session
	to the Moderator blacklist, preventing the ID from being able to make updates that
	the bot can interpret or that could propogate a new, active session.
	
	This continues until the ID is removed from the blacklist.
	
	- note: This does not deinitialize the Session, to avoid scenarios where the Session potentially needs 
	to be used by another operation at or near the timeframe where this occurs.
	*/
	public func blacklist() {
		PLog.info("Adding to blacklist - \(tag.builderID)")
		tag.sendEvent(type: .blacklist, action: .blacklist)
	}
	
	/**
	Blacklists a different session from the one attached to this delegate, which does the following:

	- Closes the Session and any associated ScheduleEvents
	- Adds the session to the Moderator blacklist, preventing the ID from being able to make updates that
	the bot can interpret or that could propogate a new, active session.

	This continues until the ID is removed from the blacklist.
	
	- note: This will only work with Sessions that subclass from ChatSession or UserSession - all else will fail.
	*/
	
	// This has been commented out to prevent unforeseen problems in how Session removal occurs.
	/*
	func blacklist(sessions: Session...) {
		
		for session in sessions {
			
			if session is UserSession || session is ChatSession {
				
			}
		}
	}
	*/

}
