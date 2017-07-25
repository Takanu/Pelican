
import Foundation
import Vapor
import FluentProvider


/**
A set of identifying information belonging to a Session, given to delegates to both perform basic callbacks to Pelican
for tasks such as Telegram API calls, as well as enabling delegates to identify and modify it's owning session through
Pelican in basic ways (such as removing the Session from active use if a Timeout condition is achieved).

- note: The data contained cannot be changed once created, this is strictly a reference and callback type.
*/
public struct SessionTag: Equatable {
	
	/// The relative identifying ID for a session.  Could be a user ID, chat ID or other types of session identification.
	var sessionID: Int
	var builderID: Int
	
	var getSessionID: Int { return sessionID }
	var getBuilderID: Int { return builderID }
	
	var sendRequestCallback: (TelegramRequest) -> (TelegramResponse)
	var sendEventCallback: (SessionEvent) -> ()
	
	
	init(sessionID: Int, builderID: Int, request: @escaping (TelegramRequest) -> (TelegramResponse), event: @escaping (SessionEvent) -> ()) {
		
		self.sessionID = sessionID
		self.builderID = builderID
		
		self.sendRequestCallback = request
		self.sendEventCallback = event
	}
	
	/**
	Sends a TelegramRequest to Pelican, to be sent as a bot API request.
	- returns: A response from Telegram.
	*/
	func sendRequest(_ request: TelegramRequest) -> TelegramResponse {
		
		return sendRequestCallback(request)
	}
	
	/**
	Sends an event request to Pelican, to perform a certain operation on the Session this tag belongs to.
	*/
	func sendEvent(type: SessionEventType, action: SessionEventAction) {
		
		let event = SessionEvent(tag: self, type: type, action: action)
		sendEventCallback(event)
	}
	
	
	public static func ==(lhs: SessionTag, rhs: SessionTag) -> Bool {
		
		if lhs.sessionID == rhs.sessionID &&
			lhs.builderID == rhs.builderID { return true }
		
		return false
	}
}

/**
TBW
*/
public protocol Session {
	
	// CORE DATA
	/// The ID of the builder that created this session, used by Pelican when events are generated from this session.
	var builderID: Int { get }
	
	
	// DELEGATES AND CONTROLLERS
	/// Handles and matches user requests to available bot functions based on user-defined patterns and behaviours.
	var routes: RouteController { get }
	/// Stores what Moderator-controlled permissions the Session has.
	var permissions: Permissions { get }
	
	
	// CALLBACKS
	/// The "tag" of a session, holding key details that allow it to be identified by Pelican.  Passed to delegates for events.
	var tag: SessionTag { get }
	
	
	// TIME AND ACTIVITY
	/// The time the session was first created.
	var timeStarted: Date { get }
	
	
	/** A standard initialiser for a Session, which includes all the required information to setup any delegates it might have. */
	init(bot: Pelican, builder: SessionBuilder, update: Update)
	
	
	/** Performs any post-initialiser setup, like setting initial routes. */
	func postInit()
	
	/** Performs any functions required to prepare the Session for removal from the Builder, which can occur when a Session or one
	of it's delegates requests Pelican to remove it. */
	func setupRemoval()
	
	
	/** Receives updates from Pelican to be used to find matching Routes and Prompts (in ChatSessions only).  Returns SessionRequests that
	Pelican uses to make requests to Telegram with. */
	func update(_ update: Update)
	
}

extension Session {
	
	// Receives a message from the TelegramBot to check whether in the current state anything can be done with it
	public func update(_ update: Update) {
		
		// This needs revising, whatever...
		_ = routes.routeRequest(update: update, type: update.type)
		
	}
	
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		
		if lhs.tag == rhs.tag { return true }
		
		return false
	}
}





