
import Foundation
import Vapor
import FluentProvider


/**
The king-daddy of Pelican, Sessions encapsulate an interaction point between you and a type of interaction on Telegram.

The protocol is a shell that defines the minimum amount of content required in order to function.  Extend it's functionality
by adding Modules from the folder to your own custom sessions.
*/
public protocol Session {
	
	// CORE DATA
	/// The "tag" of a session, holding key identifying details that allow it to be identified by Pelican, and is also passed to delegates for both identification and callback events.
	var tag: SessionTag { get }
	
	
	// DELEGATES AND CONTROLLERS
	/// The initial route that all updates to this session will be sent to.  Routes are used to handle and matches user requests to available bot functions based on user-defined patterns and behaviours.
	var baseRoute: Route { get }
	
	
	// TIME AND ACTIVITY
	/// The time the session was first created.
	var timeStarted: Date { get }
	
	
	/** A standard initialiser for a Session, which includes all the required information to setup any delegates it might have. */
	init(bot: Pelican, tag: SessionTag, update: Update)
	
	/** Performs any post-initialiser setup, like setting initial routes. */
	func postInit()
	
	/** TEMP NAME, PLEASE CHANGE ME.  Performs any functions required to prepare the Session for removal from the Builder, which can occur when a Session or one
	of it's delegates requests Pelican to remove it.  This function should never send the closure event itself, use this to clean up any custom types before the Session is removed.*/
	func cleanup()
	
	/** Receives updates from Pelican to be used to find matching Routes and Prompts (in ChatSessions only).  Returns SessionRequests that
	Pelican uses to make requests to Telegram with. */
	func update(_ update: Update)
	
}

extension Session {
	
	/** Closes the session, deinitialising all modules and removing itself from the associated SessionBuilder. */
	public func close() {
		self.tag.sendEvent(type: .other, action: .remove)
	}
	
	// Receives a message from the TelegramBot to check whether in the current state anything can be done with it
	public func update(_ update: Update) {
		
		// This needs revising, whatever...
		_ = baseRoute.handle(update)
		
	}
	
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		
		if lhs.tag == rhs.tag { return true }
		
		return false
	}
}





