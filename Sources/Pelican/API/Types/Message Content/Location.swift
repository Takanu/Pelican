//
//  Location.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

final public class Location: TelegramType, MessageContent, Model {
	public var storage = Storage()
	public var contentType: String = "location" // MessageType conforming variable for Message class filtering.
	public var method: String = "/sendLocation" // SendType conforming variable for use when sent
	
	public var latitude: Float
	public var longitude: Float
	
	public init(latitude: Float, longitude: Float) {
		self.latitude = latitude
		self.longitude = longitude
	}
	
	// SendType conforming methods to send itself to Telegram under the provided method.
	public func getQuery() -> [String:NodeConvertible] {
		let keys: [String:NodeConvertible] = [
			"longitude": longitude,
			"latitude": latitude]
		
		return keys
	}
	
	// Model conforming methods
	public required init(row: Row) throws {
		latitude = try row.get("latitude")
		longitude = try row.get("longitude")
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("latitude", latitude)
		try row.set("longitude", longitude)
		
		return row
	}
}
