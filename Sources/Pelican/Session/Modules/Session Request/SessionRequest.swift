//
//  MethodRequest.swift
//  Pelican
//
//  Created by Ido Constantine on 10/04/2018.
//

import Foundation

/**
A delegate to `SessionManager` that allows other sessions to create and modify already existing sessions.

- note: This feature for users of versions earlier than 0.8 replaces the Linked Session functionality.
*/
public class SessionRequest {
	
	/// The session manager belonging to the bot, used for "most" requests.
	fileprivate var manager: SessionManager
	
	/// A PelicanBot callback that enables the creation of other sessions.
	fileprivate var createSessionCallback: (SessionTag, String) -> (Session?)
	
	init(bot: PelicanBot) {
		self.manager = bot.sessionManager
		self.createSessionCallback = bot.createSession
	}
	

	/**
	Attempts to create a new Session based on a given Builder and Telegram ID.
	
	- returns: The new Session if successfully created.
	*/
	public func createNewSession(tag: SessionTag, telegramID: String) -> Session? {
		return createSessionCallback(tag, telegramID)
	}
	
	/**
	Attempts to return a session based on the given Telegram ID and type.  This function will return any
	session that matches the given ID and type across any builder.
	
	- returns: A Session array that corresponds with the given information if available, or nil if not.
	*/
	public func getSession(tag: SessionTag) -> Session? {
			return manager.getSession(tag: tag)
	}
	
	/**
	Attempts to return one or more sessions from a specific builder, using a Telegram ID.  This function will
	only return any sessions that match the given ID for a single builder, identified by the SessionTag provided.
	
	- returns: A Session array that corresponds with the given information if available, or nil if not.
	*/
	public func getSessions(forBuilder tag: SessionTag, telegramID: String) -> [Session]? {
		 return manager.getSessions(forBuilder: tag, telegramID: telegramID)
	}
	
	/**
	Submit work to be performed on a specific session's DispatchQueue.
	
	- returns: True if the work could be submitted, false if not.
	*/
	@discardableResult
	public func submitSessionWork(withTag tag: SessionTag, work: @escaping () -> ()) -> Bool {
		return manager.submitSessionWork(withTag: tag, work: work)
	}
	
	
	@discardableResult
	public func deleteSession(fromBuilder tag: SessionTag, telegramID: String) -> Bool {
		return manager.deleteSession(fromBuilder: tag, telegramID: telegramID)
	}
	
	/**
	Deletes any sessions in any builder that matches the given Telegram ID and type.
	
	- warning: It's not advised to delete the session requesting the deletion, just use close() instead.
	*/
	@discardableResult
	public func deleteSessions(telegramID: String, type: SessionIDType) -> Bool {
		return manager.deleteSessions(telegramID: telegramID, type: type)
	}
	
	/**
	Deletes a single session using just the SessionTag that belongs to it.
	
	- warning: It's not advised to do this to the session requesting the deletion, just use close() instead.
	*/
	@discardableResult
	public func deleteSession(tag: SessionTag) -> Bool {
		return manager.deleteSession(tag: tag)
	}
	
}
