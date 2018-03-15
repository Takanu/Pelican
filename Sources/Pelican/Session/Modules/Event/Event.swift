//
//  SessionEvent.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 06/07/2017.
//
//

import Foundation


public enum SessionEventType: String {
	case timeout
	case flood
	case blacklist
	case other
}

public enum SessionEventAction: String {
	case remove
	case blacklist
}

/**
Defines an event change by the Session that Pelican needs to know about, based on an 
automatic trigger called by one of it's delegates.
*/
public class SessionEvent {
	
	var tag: SessionTag
	var type: SessionEventType
	var action: SessionEventAction
	
	init(tag: SessionTag, type: SessionEventType, action: SessionEventAction) {
		self.tag = tag
		self.type = type
		self.action = action
	}
}
