//
//  InlineQuery.swift
//  Pelican
//
//  Created by Takanu Kyriako on 19/12/2017.
//

import Foundation


/**
Represents an incoming inline query. When the user sends an empty query, your bot could return some default or trending results.
*/
public struct InlineQuery: UpdateModel, Codable {
	
	// Unique identifier for this query.
	public var id: String
	
	// The sender.
	public var from: User
	
	// Text of the query (up to 512 characters).
	public var query: String
	
	// Offset of the results to be returned, is bot-controllable.
	public var offset: String
	
	// Sender location, only for bots that request it.
	public var location: Location?
	
	init(id: String, user: User, query: String, offset: String, location: Location? = nil) {
		self.id = id
		self.from = user
		self.query = query
		self.offset = offset
		self.location = location
	}
	
}
