//
//  Pelican+Delegates.swift
//  Pelican
//
//  Created by Takanu Kyriako on 24/08/2017.
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
		
		// If we have a message file, we need to handle this separately
		if request.content is MessageFile {
			
			do {
				let fileForm = try cache.getFormEntry(forFile: request.content as! MessageFile)
				request.form.merge(fileForm, uniquingKeysWith: { (current, _) in current } )
				
			} catch {
				
				PLog.error(String(describing: error))
				
			}
		}
		
		
		// Build a new request with the correct URI and fetch the other data from the Session Request
		// The query function tower is due to a bug where assigning the query as a node forces URL encoding, which URLComponent already applies.
		/// The nasty Query URL chaining is due to some automated url encoding it perform itself when assigned in this manner without telling you.
		let uri = URI.init(scheme: "https",
									 userInfo: nil,
									 hostname: "api.telegram.org",
									 port: nil,
									 path: "/bot" + apiKey + "/" + request.methodName,
									 query: try! request.query.makeNode(in: nil).formURLEncoded().makeString().removingPercentEncoding,
									 fragment: nil)
		
		let vaporRequest = Request(method: .post, uri: uri)
		
		// If we have a message file, add the form data (doing this regardless will break normal requests)
		if request.content is MessageFile {
			vaporRequest.formData = request.form
		}
		
		
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
