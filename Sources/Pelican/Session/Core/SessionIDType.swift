//
//  SessionIDType.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation

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
