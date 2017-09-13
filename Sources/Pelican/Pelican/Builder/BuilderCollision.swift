//
//  BuilderCollision.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation
import Vapor

/**
Defines a return result for the SessionBuilder's `collision` function, that determines how it will operate if the update that it captured
has also been captured by other builders.
*/
public enum BuilderCollision: String {
	
	/// Used when you wish for the builder to do nothing with the update.
	case pass
	/// Used when you wish for the session that would have executed the update to be included for other capturing sessions to use instead.
	case include
	/// Used when you wish for the session to execute the update.
	case execute
	/// Used when you wish to both pass the session to other sessions that can accept the update, and allow it to try and execute on it.
	case all
}

