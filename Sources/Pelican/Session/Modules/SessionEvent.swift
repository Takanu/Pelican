//
//  SessionEvent.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 06/07/2017.
//
//

import Foundation
import Vapor

enum SessionEventType: String {
	case timeout
	case flood
	case blacklist
}

/**
Defines an event change by the Session that Pelican needs to know about.
*/
public class SessionEvent {
	
	var targetID: Int
	var targetType: String
	var event: SessionEventType
	
	init(targetID: Int, targetType: String, event: SessionEventType) {
		self.targetID = targetID
		self.targetType = targetType
		self.event = event
	}
}
