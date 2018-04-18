//
//  Builder.swift
//
//  Created by Takanu Kyriako on 07/07/2017.
//

import Foundation


/**
Defines a class that will be used by Pelican to automatically generate Sessions based on two key components:
- **Spawner:** A function that checks an update to see whether or not it matches given criteria in that function, returning a non-nil ID value if true.
	Pre-built spawners are available through the `Spawn` class, or you can just make your own so long as they conform to the type `(Update) -> Int?`.
- **Session:** The type of session to be created if the spawner succeeds.

## SessionBuilder Example
```
let chatSpawner = Spawn.perChatID(updateType: [.message], chatType: [.private])

pelican.addBuilder(SessionBuilder(spawner: chatSpawner, session: ChatSession.self, setup: nil) )
```
*/
public class SessionBuilder {
	
	/// The name of the builder.
	public private(set) var name: String
	
	/** The identifier for the Builder, to allow Pelican to identify and send events to it from an individual Session.
	This is an internal ID and should not be changed. */
	public private(set) var id = UUID()
	
	/// A function that checks an update to see whether or not it matches given criteria in that function, returning a non-nil value if true.
	public var spawner: (Update) -> String?
	
	/// The type of identification the spawner function generates, which is then used to identify a Session.
	public private(set) var idType: SessionIDType
	
	/// The session type that the builder creates for handling updates.
	public private(set) var sessionType: Session.Type
	
	/** An optional function type that can be used to initialise a Session type in a custom way, such as if it has any additional initialisation paramaters. 
	If left empty, the default Session initialiser will be used. */
	var setup: ((PelicanBot, SessionTag) -> (Session))?
	
	/// The number of sessions the builder can have active at any given time.  Leave at 0 for no limit.
	public var maxSessions: Int = 0
	
	/** The sessions that have been spawned by the builder and are currently active.  Sessions are categorised by their
	Telegram ID, followed by their UUID if more than one session has been created for the same Telegram ID. */
	var sessions = SynchronisedDictionary<String, [Session]>()
	
	/// Returns the number of sessions being managed by the builder.
	public var getSessionCount: Int { return sessions.count }
	
	
	/**
	Creates a SessionBuilder, responsible for automatically generating different session types.
	
	- parameter name: The name of the builder, used to fetch, add and delete sessions from it at
	a later date.  Ensure the names you provide are unique for each builder.
	- parameter spawner: A function that checks an update to see whether or not it matches given
	criteria in that function, returning a non-nil ID value if true.
	- parameter setup: An optional function type that can be used to setup Sessions when created
	to be given anything else that isn't available during initialisation, such as specific Flood
	Limits and Timeouts.
	*/
	public init(name: String,
							spawner: @escaping (Update) -> String?,
							idType: SessionIDType,
							sessionType: Session.Type,
							setup: ((PelicanBot, SessionTag) -> (Session))?) {
		
		self.name = name
		self.spawner = spawner
		self.idType = idType
		self.sessionType = sessionType
		self.setup = setup
	}
	
	/**
	Checks the update to decide whether or not this builder can handle the update.
	
	- returns: True if the builder can use the update, and false if not
	*/
	func checkUpdate(_ update: Update) -> Bool {
		if spawner(update) != nil {
			return true
		}
		
		return false
	}
	
	/**
	Creates a new session based on the given Telegram ID.  This will happen even if a Session already
	exists with the given ID.
	*/
	func createSession(withTag tag: SessionTag, bot: PelicanBot, telegramID: String) -> Session? {
		
		var newSession: Session?
		
		// If the setup function exists, use it
		if setup != nil {
			let tag = SessionTag(bot: bot, builder: self, id: telegramID, user: tag.user, chat: tag.chat)
			newSession = setup!(bot, tag)
		}
			
		// If it doesn't, use the default initialiser.
		else {
			let tag = SessionTag(bot: bot, builder: self, id: telegramID, user: tag.user, chat: tag.chat)
			newSession = self.sessionType.init(bot: bot, tag: tag)
			newSession?.postInit()
		}
		
		// Work out if we need to append or make a new array
		if newSession != nil {
			if sessions[telegramID] != nil {
				sessions[telegramID]?.append(newSession!)
			} else {
				sessions[telegramID] = [newSession!]
			}
		}
		
		return newSession
	}
	
	/**
	Attempts to handle the giving update by either passing it onto any existing sessions with a matching Telegram ID,
	or by creating a new session if one doesn't yet exist.
	*/
	func handleUpdate(_ update: Update, bot: PelicanBot) {
		
		var foundSessions: [Session] = []
		
		/// Check if our spawner gives us a non-nil value
		if let id = spawner(update) {
			
			/// Check if we can get a session.
			if let sessions = sessions[id] {
				foundSessions = sessions
			}
				
			// If not, see if we are able to build one within the limit.
			if getSessionCount >= maxSessions && maxSessions != 0 {
				return
			}
				
			// If not, build one
			if foundSessions.count == 0 {
				var newSession: Session?
				
				// If the setup function exists, use it
				if setup != nil {
					
					let tag = SessionTag(bot: bot, builder: self, id: id, user: update.from, chat: update.chat)
					newSession = setup!(bot, tag)
				}
					
				// If it doesn't, use the default initialiser.
				else {
					let tag = SessionTag(bot: bot, builder: self, id: id, user: update.from, chat: update.chat)
					newSession = self.sessionType.init(bot: bot, tag: tag)
					newSession?.postInit()
				}
				
				/// Create a new array for the session
				if newSession != nil {
					sessions[id] = [newSession!]
					foundSessions = [newSession!]
				}
			}
		}
		
		// For any sessions we got, pass the update on.
		foundSessions.forEach {
			$0.update(update)
		}
	}
	
	/**
	Attempts to return a session based on the given SessionTag.
	
	- returns: A session that corresponds with the given tag if it both matches the Builder ID and
	if the Builder has the Session being asked for.
	*/
	func getSession(tag: SessionTag) -> Session? {
		if self.id != tag.builderID { return nil }
		
		if let foundSessions = sessions[tag.id] {
			for session in foundSessions {
				if session.tag == tag {
					return session
				}
			}
		}
		
		return nil
	}
	
	/**
	Attempts to return a session based on the given SessionTag.
	
	- returns: A session that corresponds with the given tag if it both matches the Builder ID and
	if the Builder has the Session being asked for.
	*/
	func getSessions(telegramID: String) -> [Session]? {
		if let foundSessions = sessions[telegramID] {
			return foundSessions
		}
		
		return nil
	}
	
	/**
	Attempts to delete any Sessions that match the given Telegram ID.  This process will also execute a
	Session's cleanup() function to removeany necessary references for garbage collection purposes.
	*/
	@discardableResult
	func deleteSessions(telegramID: String) -> Bool {
		
		if let foundSessions = sessions[telegramID] {
			foundSessions.forEach {
				$0.cleanup()
			}
			sessions.removeValue(forKey: telegramID)
			return true
		}
		
		return false
	}
	
	/**
	Attempts to delete a Session, given the SessionTag that identifies it.  This process will also execute a
	Session's cleanup() function to removeany necessary references for garbage collection purposes.
	*/
	@discardableResult
	func deleteSession(tag: SessionTag) -> Bool {
		if tag.builderID != self.id { return false }
		
		if let foundSessions = sessions[tag.id] {
			foundSessions.forEach {
				$0.cleanup()
			}
			
			sessions.removeValue(forKey: tag.id)
			return true
		}
		
		return false
	}
	
	/**
	Removes all sessions from the builder.  This will also execute a Session's cleanup() function to remove
	any necessary references for garbage collection purposes.
	*/
	func clear() {
		sessions.forEach { (key, value) in
			value.forEach {
				$0.cleanup()
			}
		}
		
		sessions.removeAll()
	}
	
}



