
import Foundation
import Vapor
import FluentProvider


public protocol Session {
	
	// CORE DATA
	/// The ID of the builder that created this session, used by Pelican when events are generated from this session.
	var builderID: Int { get set }
	
	
	// DELEGATES AND CONTROLLERS
	/// Handles and matches user requests to available bot functions based on user-defined patterns and behaviours.
	var routes: RouteController { get set }
	/// Stores what Moderator-controlled permissions the Session has.
	var permissions: Permissions { get }
	
	
	// CALLBACKS
	var sendRequest: (TelegramRequest) -> (TelegramResponse) { get }
	var sendEvent: (SessionEvent) -> () { get }
	
	
	// TIME AND ACTIVITY
	/// The time the session was first created.
	var timeStarted: Date { get }
	/// The length of time (in seconds) required for the session to be idle or without activity, before it has the potential to be deleted by Pelican.
	var timeoutLength: Int { get set }
	/// The time the session was last active, as a result of it receiving an update.
	var timeLastActive: Date { get }
	/// The flood conditions and state for the current session.
	//var flood = FloodLimit { get set }
	
	
	/** A standard initialiser for a Session, which includes all the required information to setup any delegates it might have. */
	init(bot: Pelican, builder: SessionBuilder, update: Update)
	
	
	/** Performs any post-initialiser setup, like setting initial routes. */
	func postInit()
	
	
	/** Receives updates from Pelican to be used to find matching Routes and Prompts (in ChatSessions only).  Returns SessionRequests that
	Pelican uses to make requests to Telegram with. */
	func update(_ update: Update)
	
}

extension Session {
	
	// Receives a message from the TelegramBot to check whether in the current state anything can be done with it
	public func update(_ update: Update) {
		
		// This needs revising, whatever...
		let handled = routes.routeRequest(update: update, type: update.type, session: self)
		
	}
	
	/// Returns the time the session was last active, as a result of it receiving an update.
	public var getTimeLastActive: Date { return timeLastActive }
	
	/// Returns whether or not the session has timed out, based on it's timeout limit and the time it was last interacted with.
	public var hasTimeout: Bool {
		
		let calendar = Calendar.init(identifier: .gregorian)
		let comparison = calendar.compare(timeLastActive, to: Date(), toGranularity: .second)
		
		if comparison.rawValue >= timeoutLength && timeoutLength != 0 { return true }
		return false
	}
}





