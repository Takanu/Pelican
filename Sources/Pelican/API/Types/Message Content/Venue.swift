//
//  Venue.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/**
Represents a different type of location, for venue-like venuing.
*/
final public class Venue: TelegramType, MessageContent {
	
	// STORAGE AND IDENTIFIERS
	public var contentType: String = "venue"
	public var method: String = "sendVenue"
	
	// PARAMETERS
	/// The location of the venue.
	public var location: Location
	
	/// Location title.
	public var title: String
	
	/// Address of the venue.
	public var address: String
	
	/// Foursquare identifier of the venue if known.
	public var foursquareID: String?
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case location
		case title
		case address
		case foursquareID = "foursquare_id"
	}
	
	public init(location: Location, title: String, address: String, foursquareID: String? = nil) {
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
}
