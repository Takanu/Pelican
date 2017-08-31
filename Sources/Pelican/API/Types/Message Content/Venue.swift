//
//  Venue.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

final public class Venue: TelegramType, MessageContent {
	public var storage = Storage()
	public var contentType: String = "venue" // MessageType conforming variable for Message class filtering.
	public var method: String = "/sendVenue" // SendType conforming variable for use when sent
	
	public var location: Location
	public var title: String
	public var address: String
	public var foursquareID: String?
	
	public init(location: Location, title: String, address: String) {
		self.location = location
		self.title = title
		self.address = address
	}
	
	// SendType conforming methods to send itself to Telegram under the provided method.
	public func getQuery() -> [String:NodeConvertible] {
		var keys: [String:NodeConvertible] = [
			"latitude": location.latitude,
			"longitude": location.longitude,
			"title": title,
			"address": address
		]
		
		if foursquareID != nil { keys["foursquare_id"] = foursquareID }
		return keys
	}
	
	// NodeRepresentable conforming methods
	public required init(row: Row) throws {
		location = try row.get("location")
		title = try row.get("title")
		address = try row.get("address")
		foursquareID = try row.get("foursquare_id")
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("location", location)
		try row.set("title", title)
		try row.set("address", address)
		try row.set("foursquare_id", foursquareID)
		
		return row
	}
}
