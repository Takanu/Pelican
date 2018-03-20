//
//  Pelican+Delegates.swift
//  Pelican
//
//  Created by Takanu Kyriako on 24/08/2017.
//

import Foundation

extension PelicanBot {
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
			
			switch event.tag.idType {
				
			case .chat:
				mod.addToBlacklist(chatIDs: event.tag.id)
			case .user:
				mod.addToBlacklist(userIDs: event.tag.id)
			default:
				return
			}
			
			sessions.forEach( { $0.removeSession(tag: event.tag) } )
			
		}
		
		
	}
}
