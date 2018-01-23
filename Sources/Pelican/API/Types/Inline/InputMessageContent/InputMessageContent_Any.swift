//
//  File.swift
//  Pelican
//
//  Created by Ido Constantine on 22/12/2017.
//

import Foundation

/**
Used as a basic means by which to link all InputMessageContent types
*/
public protocol InputMessageContent_Any: Codable {
	
	// FIXME: An unusual hold-over for Codable, not sure if I need this anymore.
	static var type: InputMessageContentType { get }
	
}
