//
//  File.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation
import Vapor
import FluentProvider

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
	@discardableResult
	public func sendRequest(_ request: TelegramRequest) -> TelegramResponse {
		
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
		
		if lhs.sessionID == rhs.sessionID &&
			lhs.builderID == rhs.builderID { return true }
		
		return false
	}
}
