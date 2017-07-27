//
//  SessionModerator.swift
//  PelicanTests
//
//  Created by Ido Constantine on 26/07/2017.
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
	/// The titles the Session currently has.
	private var titles: [String]
	
	private var changeTitleCallback: (SessionTag, String, Bool) -> ()
	
	public var getID: Int { return tag.getSessionID }
	public var getTitles: [String] { return titles }
	
	
	/**
	Attempts to create a SessionModerator.
	- warning: This should not be used under any circumstances if your session does not represent a User or Chat session, and 
	if the SessionBuilder used to create is is not using User or Chat IDs respectively.  🙏
	*/
	init?(tag: SessionTag, moderator: Moderator) {
		
		self.tag = tag
		self.changeTitleCallback = moderator.changeTitle(tag:title:remove:)
		self.titles = moderator.getTitles(forID: tag.sessionID, type: tag.sessionIDType)
		
		if tag.sessionIDType != .chat || tag.sessionIDType != .user { return }
	}
	
	/**
	Adds a title to the session ID.
	*/
	public func add(_ title: String) {
		
		if titles.contains(title) == true { return }
		titles.append(title)
		
		changeTitleCallback(tag, title, false)
	}
	
	/**
	Removes a title from the session ID, if associated with it.
	*/
	public func remove(_ title: String) {
		
		if let index = titles.index(of: title) {
			titles.remove(at: index)
		}
		
		changeTitleCallback(tag, title, true)
	}
	
	/**
	Checks to see whether the Session has a given title.
	- returns: True if it does, false if not.
	*/
	public func checkTitle(_ title: String) -> Bool {
		
		if titles.contains(title) { return true }
		return false
	}
	
	/**
	Removes all titles associated with this session ID.
	*/
	public func clearTitles() {
		
		for title in titles {
			changeTitleCallback(tag, title, true)
		}
		
		titles.removeAll()
		
		
	}
	
	/**
	Blacklists the Session ID, which does the following:
	- Closes the Session and any associated ScheduleEvents
	- Adds the session to the Moderator blacklist, preventing the ID from being able to make updates that
	the bot can interpret or that could propogate a new, active session.
	
	This continues until the ID is removed from the blacklist.
	
	- note: This does not deinitialize the Session, to avoid scenarios where the Session potentially needs 
	to be used by another operation at or near the timeframe where this occurs.
	*/
	public func blacklist() {
		
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
