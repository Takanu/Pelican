//
//  BuilderManager.swift
//  Pelican
//
//  Created by Ido Constantine on 09/04/2018.
//

import Foundation

/**
This type both manages and allows simplified internal access to all the builders that the bot has, while enabling
Sessions to also directly access other sessions with reduced API access.
*/
class SessionManager {
	
	/// The session builders that the PelicanBot currently has.
	fileprivate var builders = SynchronizedArray<SessionBuilder>()
	
	init() { }
	
	/**
	Attempts to return a session based on the given Telegram ID and type.  This function will return any
	session that matches the given ID and type across any builder.
	
	- returns: A Session array that corresponds with the given information if available, or nil if not.
	*/
	func addBuilders(_ incomingBuilders: SessionBuilder...) {
		builders.append(incomingBuilders)
	}
	
	/**
	Attempts to return a session based on the given Telegram ID and type.  This function will return any
	session that matches the given ID and type across any builder.
	
	- returns: A Session array that corresponds with the given information if available, or nil if not.
	*/
	func addBuilders(_ incomingBuilders: [SessionBuilder]) {
		builders.append(incomingBuilders)
	}
	
	/**
	Attempts to create a new Session based on a given Builder and Telegram ID.

	- returns: The new Session if successfully created.
	*/
	public func createNewSession(tag: SessionTag, bot: PelicanBot, telegramID: String) -> Session? {
		if let builder = builders.first(where: {$0.id == tag.builderID}) {
			return builder.createSession(withTag: tag, bot: bot, telegramID: telegramID)
		}
		return nil
	}
	
	/**
	Attempts to return a session based on the given Telegram ID and type.  This function will return any
	session that matches the given ID and type across any builder.
	
	- returns: A Session array that corresponds with the given information if available, or nil if not.
	*/
	public func getSession(tag: SessionTag) -> Session? {
		if let builder = builders.first(where: {$0.id == tag.builderID}) {
			return builder.getSession(tag: tag)
		}
		
		return nil
	}
	
	/**
	Attempts to return one or more sessions from a specific builder, using a Telegram ID.  This function will
	only return any sessions that match the given ID for a single builder, identified by the SessionTag provided.
	
	- returns: A Session array that corresponds with the given information if available, or nil if not.
	*/
	public func getSessions(forBuilder tag: SessionTag, telegramID: String) -> [Session]? {
		if let builder = builders.first(where: {$0.id == tag.builderID}) {
			return builder.getSessions(telegramID: telegramID)
		}
		return nil
	}
	
	/**
	Attempts to return one or more sessions from a specific builder, using the builder's name and a Telegram ID.
	
	- returns: A Session array that corresponds with the given information if available, or nil if not.
	*/
	public func getSessions(forBuilder builderName: String, telegramID: String) -> [Session]? {
		if let builder = builders.first(where: {$0.name == builderName}) {
			return builder.getSessions(telegramID: telegramID)
		}
		return nil
	}
	
	/**
	Submit work to be performed on a specific session's DispatchQueue.
	
	- returns: True if the work could be submitted, false if not.
	*/
	@discardableResult
	func submitSessionWork(withTag tag: SessionTag, work: @escaping () -> ()) -> Bool {
		if let foundSession = getSession(tag: tag) {
			foundSession.dispatchQueue.async(work)
			return true
		}
		
		return false
	}
	
	
	@discardableResult
	public func deleteSession(fromBuilder tag: SessionTag, telegramID: String) -> Bool {
		var result = false
		
		if let builder = builders.first(where: {$0.id == tag.builderID}) {
			result = builder.deleteSessions(telegramID: telegramID)
		}
		
		return result
	}
	
	/**
	Deletes any sessions in any builder that matches the given Telegram ID and type.
	
	- warning: It's not advised to delete the session requesting the deletion, just use close() instead.
	*/
	@discardableResult
	public func deleteSessions(telegramID: String, type: SessionIDType) -> Bool {
		var result = false
		
		let foundBuilders = builders.filter({$0.idType == type})
		for builder in foundBuilders {
			let bResult = builder.deleteSessions(telegramID: telegramID)
			if bResult == true { result = true }
		}
		
		return result
	}
	
	/**
	Deletes a single session using just the SessionTag that belongs to it.
	
	- warning: It's not advised to do this to the session requesting the deletion, just use close() instead.
	*/
	@discardableResult
	public func deleteSession(tag: SessionTag) -> Bool {
		let builder = builders.first(where: {$0.id == tag.builderID})
		return builder?.deleteSession(tag: tag) ?? false
	}
	
	/**
	Attempts to distribute a set of given updates to the session builders it manages.  Any builder that
	where it can accept the Telegram ID of the update but no session has been created, will create a new
	session to enable handling.
	*/
	func handleUpdates(_ updates: [Update], bot: PelicanBot) {
		builders.forEach {
			for update in updates {
				$0.handleUpdate(update, bot: bot)
			}
		}
	}
	
	/**
	Clears all builders from the manager.  This will also destroy all sessions.
	*/
	private func clear() {
		builders.forEach {
			$0.clear()
		}
	}
	
}
