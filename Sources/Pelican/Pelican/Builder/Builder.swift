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
	
	/** The identifier for the Builder, to allow Pelican to identify and send events to it from an individual Session.
	This is an internal ID and should not be changed. */
	public private(set) var id = UUID()
	
	/// A function that checks an update to see whether or not it matches given criteria in that function, returning a non-nil value if true.
	public var spawner: (Update) -> Int?
	
	/// The type of identification the spawner function generates, which is then used to identify a Session.
	public private(set) var idType: SessionIDType
	
	/// The session type that the builder creates for handling updates.
	public private(set) var session: Session.Type
	
	/** An optional function type that can be used to initialise a Session type in a custom way, such as if it has any additional initialisation paramaters. 
	If left empty, the default Session initialiser will be used. */
	var setup: ((PelicanBot, SessionTag, Update) -> (Session))?
	
	/** An optional closure designed to resolve "collisions", when two or more builders capture the same update.
	The closure must return a specific enumerator that determines whether based on the collision, the builder will either not 
	execute the update for a session, include itself in the update object for other sessions to use, or execute it.
	
	- note: If left unused, the builder will always execute an update it has successfully captured, even if another builder has also captured it.
	*/
	public var collision: ((PelicanBot, Update) -> (BuilderCollision))?
	
	/// The number of sessions the builder can have active at any given time.  Leave at 0 for no limit.
	public var maxSessions: Int = 0
	
	/// The sessions that have been spawned by the builder and are currently active.
	var sessions: [Int:Session] = [:]
	
	/// Returns the number of sessions being managed by the builder.
	public var getSessionCount: Int { return sessions.count }
	
	
	/**
	Creates a SessionBuilder, responsible for automatically generating different session types.
	
	- parameter spawner: A function that checks an update to see whether or not it matches given
	criteria in that function, returning a non-nil ID value if true.
	- parameter setup: An optional function type that can be used to setup Sessions when created
	to be given anything else that isn't available during initialisation, such as specific Flood
	Limits and Timeouts.
	*/
	public init(spawner: @escaping (Update) -> Int?,
							idType: SessionIDType,
							session: Session.Type,
							setup: ((PelicanBot, SessionTag, Update) -> (Session))?) {
		
		self.spawner = spawner
		self.idType = idType
		self.session = session
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
	Attempts to return a session belonging to the builder based on a given update.  If one doesn't exist, it will be created.
	
	- returns: A session that corresponds with the given update if the Builder either has it or is able
	to spawn it, or nil if not.
	*/
	func getSession(bot: PelicanBot, update: Update) -> Session? {
		
		/// Check if our spawner gives us a non-nil value
		if let id = spawner(update) {
			
			/// Check if we can get a session.
			if let session = sessions[id] {
				return session
			}
				
			// If not, see if we are able to build one within the limit.
			if getSessionCount >= maxSessions {
				return nil
			}
				
			// If not, build one
			else {
				
				// If the setup function exists, use it
				if setup != nil {
					
					let tag = SessionTag(bot: bot, builder: self, id: id)
					let session = setup!(bot, tag, update)
					sessions[id] = session
					return session
				}
					
				// If it doesn't, use the default initialiser.
				else {
					let tag = SessionTag(bot: bot, builder: self, id: id)
					let session = self.session.init(bot: bot, tag: tag, update: update)
					session.postInit()
					
					sessions[id] = session
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
	func findBuilder(tag: SessionTag) -> Session? {
		if self.id != tag.builderID { return nil }
		
		if let session = sessions[tag.id] {
			return session
		} else {
			return nil
		}
	}
	
	/**
	Attempts to generate or use a session with the builder using a given update object.
	
	- parameter update: The update to use to see if a session can be built with it.
	- returns: True if the update was successfully used, and false if not.
	*/
	func execute(bot: PelicanBot, update: Update) -> Bool {
		
		if let session = getSession(bot: bot, update: update) {
			
			session.update(update)
			return true
		}
		
		return false
	}
	
	
	/**
	Attempts to remove a Session, given the SessionTag that identifies it.
	*/
	func removeSession(tag: SessionTag) {
		
		if tag.builderID != self.id { return }
		
		if let session = sessions[tag.id] {
			session.cleanup()
			sessions.removeValue(forKey: tag.id)
		}
	}
	
}



