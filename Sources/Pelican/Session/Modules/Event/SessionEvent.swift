//
//  SessionEvent.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 06/07/2017.
//
//

import Foundation

/**
Defines an event that has occurred within a Session that Pelican needs to know about, based on an
automatic trigger called by one of it's delegates or something else.
*/
public class SessionEvent {
	
	/// The tag that belongs to the session responsible for the event.
	var tag: SessionTag
	
	/// The type of event that has occurred.
	var type: SessionEventType
	
	/// The action that should take place as a result of the event taking place.
	var action: SessionEventAction
	
	init(tag: SessionTag, type: SessionEventType, action: SessionEventAction) {
		self.tag = tag
		self.type = type
		self.action = action
	}
}

/**
Defines an event that can occur to a Session which can be signalled to Pelican.
*/
public enum SessionEventType: String {
	case timeout
	case flood
	case blacklist
	case other
}

/**
Defines an action to take when a SessionEvent is sent as a result of a `SessionEventType`.
*/
public enum SessionEventAction: String {
	case remove
	case blacklist
}
