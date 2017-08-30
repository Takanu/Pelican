//
//  Pelican+Delegates.swift
//  Pelican
//
//  Created by Ido Constantine on 24/08/2017.
//

import Foundation
import Vapor


extension Pelican {
	/**
	Sends the given requests to Telegram.
	- note: At some point this will also collect and use content sent back from Telegram in a way that makes sense,
	but I haven't thought that far yet.
	*/
	func sendRequest(_ request: TelegramRequest) -> TelegramResponse {
		
		// Build a new request with the correct URI and fetch the other data from the Session Request
		// The query function tower is due to a bug where assigning the query as a node forces URL encoding, which URLComponent already applies.
		let uri = URI.init(scheme: "https",
		                   userInfo: nil,
		                   hostname: "api.telegram.org",
		                   port: nil,
		                   path: "/bot" + apiKey + "/" + request.methodName,
		                   query: try! request.query.makeNode(in: nil).formURLEncoded().makeString().removingPercentEncoding,
		                   fragment: nil)
		
		let vaporRequest = Request(method: .post, uri: uri)
		
		// Attempt to send it and get a TelegramResponse from it.
		PLog.verbose("Telegram Request - (\(vaporRequest))")
		let response = try! client!.respond(to: vaporRequest)
		PLog.verbose("Telegram Response - (\(response))")
		
		let tgResponse = TelegramResponse(response: response)
		return tgResponse
		
	}
	
	/**
	Handles a specific event sent from a Session.
	*/
	func sendEvent(_ event: SessionEvent) {
		
		switch event.action {
			
		// In this event, the session just needs removing without any other tasks.
		case .remove:
			sessions.forEach( { $0.removeSession(tag: event.tag) } )
			
			
		// In a blacklist event, first make sure the Session ID type matches.  If not, return.
		case .blacklist:
			
			switch event.tag.getSessionIDType {
				
			case .chat:
				mod.addToBlacklist(chatIDs: event.tag.getSessionID)
			case .user:
				mod.addToBlacklist(userIDs: event.tag.getSessionID)
			default:
				return
			}
			
			sessions.forEach( { $0.removeSession(tag: event.tag) } )
			
		}
		
		
	}
}
