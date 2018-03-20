//
//  Location.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/**
Represents a real-world location, that when sent as the contents of a message, is represented by a map preview.
*/
final public class Location: TelegramType, MessageContent {
	
	// STORAGE AND IDENTIFIERS
	public var contentType: String = "location"
	public var method: String = "sendLocation"
	
	// PARAMETERS
	/// The latitude of the location.
	public var latitude: Float
	/// The longitude of the location.
	public var longitude: Float
	
	
	public init(latitude: Float, longitude: Float) {
		self.latitude = latitude
		self.longitude = longitude
	}
	
	// SendType conforming methods to send itself to Telegram under the provided method.
	public func getQuery() -> [String: Codable] {
		let keys: [String: Codable] = [
			"longitude": longitude,
			"latitude": latitude]
		
		return keys
	}
}
