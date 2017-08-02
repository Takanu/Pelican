
import Foundation
import Vapor
import FluentProvider


/**
Defines what kind of identifier a SessionTag is holding, which is important for interactions between a Session and other models
like the Moderator, whose job is to manage titles and blacklists only for Chat and User ID types.
*/
public enum SessionIDType {
	
	/// Defines a single user on Telegram.
	case chat
	/// Defines a single chat on Telegram.
	case user
	/// Defines any other type of ID, typically only existing for that specific update.  This ID will not work for any Moderator operations.
	case temporary
}


/**
A set of identifying information belonging to a Session, given to itself and it's delegates to both perform basic callbacks to Pelican
for tasks such as Telegram API calls, as well as enabling delegates to identify and modify it's owning session through
Pelican in basic ways (such as removing the Session from active use if a Timeout condition is achieved).

- note: The data contained cannot be changed once created, this is strictly a reference and callback type.
*/
public struct SessionTag: Equatable {
	
	// DATA
	/// The relative identifying ID for a session.  Could be a user ID, chat ID or other types of session identification.
	var sessionID: Int
	/// The type of Session the Tag and ID refer to.
	var sessionType: Session.Type
	/// The type of ID the session is represented by, used for more specific tasks such as Moderation.
	var sessionIDType: SessionIDType
	/// The identifier for the Builder ID, assigned by Pelican at it's creation.
	var builderID: Int
	
	
	// GETTERS
	public var getSessionID: Int { return sessionID }
	public var getSessionType: Session.Type { return sessionType }
	public var getSessionIDType: SessionIDType { return sessionIDType }
	public var getBuilderID: Int { return builderID }
	
	
	// CALLBACKS
	var sendRequestCallback: (TelegramRequest) -> (TelegramResponse)
	var sendEventCallback: (SessionEvent) -> ()
	
	
	init(bot: Pelican, builder: SessionBuilder, id: Int) {
		
		self.sessionID = id
		self.sessionType = builder.session
		self.sessionIDType = builder.idType
		self.builderID = builder.getID
		
		
		self.sendRequestCallback = bot.sendRequest(_:)
		self.sendEventCallback = bot.sendEvent(_:)
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
	/// The "tag" of a session, holding key identifying details that allow it to be identified by Pelican, and is also passed to delegates for both identification and callback events.
	var tag: SessionTag { get }
	
	
	// DELEGATES AND CONTROLLERS
	/// Handles and matches user requests to available bot functions based on user-defined patterns and behaviours.
	var routes: RouteController { get }
	
	
	// TIME AND ACTIVITY
	/// The time the session was first created.
	var timeStarted: Date { get }
	
	
	/** A standard initialiser for a Session, which includes all the required information to setup any delegates it might have. */
	init(bot: Pelican, tag: SessionTag, update: Update)
	
	/** Performs any post-initialiser setup, like setting initial routes. */
	func postInit()
	
	/** Performs any functions required to prepare the Session for removal from the Builder, which can occur when a Session or one
	of it's delegates requests Pelican to remove it. */
	func close()
	
	/** Receives updates from Pelican to be used to find matching Routes and Prompts (in ChatSessions only).  Returns SessionRequests that
	Pelican uses to make requests to Telegram with. */
	func update(_ update: Update)
	
}

extension Session {
	
	// Receives a message from the TelegramBot to check whether in the current state anything can be done with it
	public func update(_ update: Update) {
		
		// This needs revising, whatever...
		_ = routes.handle(update: update)
		
	}
	
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		
		if lhs.tag == rhs.tag { return true }
		
		return false
	}
}





