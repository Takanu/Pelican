//
//  File.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation



/**
A set of identifying information belonging to a Session, given to itself and it's delegates to both perform basic callbacks to Pelican
for tasks such as Telegram API calls, as well as enabling delegates to identify and modify it's owning session through
Pelican in basic ways (such as removing the Session from active use if a Timeout condition is achieved).

- note: The data contained cannot be changed once created, this is strictly a reference and callback type.
*/
public struct SessionTag: Equatable {
	
	// DATA
	/// The relative identifying ID for a session.  Could be a user ID, chat ID or other types of session identification.
	var storedID: Int
	
	/// The type of Session the Tag and ID refer to.
	var storedSessionType: Session.Type
	
	/// The type of ID the session is represented by, used for more specific tasks such as Moderation.
	var storedIDType: SessionIDType
	
	/// The identifier of the Builder that created this session.
	var storedBuilderID: Int
	
	
	// GETTERS
	/// The relative identifying ID for a session.  Could be a user ID, chat ID or a different, arbitrary type of session identification.
	public var id: Int { return storedID }
	
	/// The instance type that this session tag belongs to.
	public var sessionType: Session.Type { return storedSessionType }
	
	/// The type of ID the session is represented by, utilised by types like the Moderator.
	public var idType: SessionIDType { return storedIDType }
	
	/// The identifier of the Builder that created this session.
	public var builderID: Int { return storedBuilderID }
	
	
	// CALLBACKS
	var sendRequestCallback: (TelegramRequest) -> (TelegramResponse?)
	var sendEventCallback: (SessionEvent) -> ()
	
	
	init(bot: Pelican, builder: SessionBuilder, id: Int) {
		
		self.storedID = id
		self.storedSessionType = builder.session
		self.storedIDType = builder.idType
		self.storedBuilderID = builder.getID
		
		
		self.sendRequestCallback = bot.sendRequest(_:)
		self.sendEventCallback = bot.sendEvent(_:)
		
	}
	
	/**
	Sends a TelegramRequest to Pelican, to be sent as a bot API request.
	- returns: A response from Telegram.
	*/
	public func sendRequest(_ request: TelegramRequest) -> TelegramResponse? {
		
		return sendRequestCallback(request)
	}
	
	/**
	Sends an event request to Pelican, to perform a certain operation on the Session this tag belongs to.
	*/
	public func sendEvent(type: SessionEventType, action: SessionEventAction) {
		
		let event = SessionEvent(tag: self, type: type, action: action)
		sendEventCallback(event)
	}
	
	
	public static func ==(lhs: SessionTag, rhs: SessionTag) -> Bool {
		
		if lhs.id == rhs.id &&
			lhs.sessionType == rhs.sessionType &&
			lhs.idType == rhs.idType &&
			lhs.builderID == rhs.builderID { return true }
		
		return false
	}
}
