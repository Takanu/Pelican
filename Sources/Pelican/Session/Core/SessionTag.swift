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
	/// The relative identifying ID for a session.  Could be a user ID, chat ID or a different, arbitrary type of session identification.
	public private(set) var id: Int
	
	/// The type of ID the session is represented by, utilised by types like the Moderator.
	public private(set) var idType: SessionIDType
	
	/// The instance type that this session tag belongs to.
	public private(set) var sessionType: Session.Type
	
	/// The identifier of the Builder that created this session.
	public private(set) var builderID: UUID
	
	
	// CALLBACKS
	/// A callback connected to Client that allows synchronous requests to be made to Telegram.
	public private(set) var sendSyncRequestCallback: (TelegramRequest) -> (TelegramResponse?)
	
	/// A callback connected to Client that allows asynchronous requests to be made to Telegram.
	public private(set) var sendAsyncRequestCallback: (TelegramRequest, ((TelegramResponse?) -> ())? ) -> ()
	
	/// A callback connected to Pelican that can be used to notify it of key session life-cycle events.
	public private(set) var sendEventCallback: (SessionEvent) -> ()
	
	
	init(bot: PelicanBot, builder: SessionBuilder, id: Int) {
		
		self.id = id
		self.sessionType = builder.session
		self.idType = builder.idType
		self.builderID = builder.id
		
		self.sendSyncRequestCallback = bot.client.syncRequest
		self.sendAsyncRequestCallback = bot.client.asyncRequest
		self.sendEventCallback = bot.sendEvent(_:)
		
	}
	
	/**
	Sends a TelegramRequest.
	- returns: A TelegramResponse containing the data received if successful.
	*/
	public func sendSyncRequest(_ request: TelegramRequest) -> TelegramResponse? {
		
		return sendSyncRequestCallback(request)
	}
	
	/**
	Sends a TelegramRequest from Pelican asynchronously.
	*/
	public func sendAsyncRequest(_ request: TelegramRequest, callback: ((TelegramResponse?) -> ())? ) {
		
		sendAsyncRequestCallback(request, callback)
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
