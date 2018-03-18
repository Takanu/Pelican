//
//  InputMessageVenue.swift
//  Pelican
//
//  Created by Takanu Kyriako on 19/12/2017.
//

import Foundation

/**
Represents the content of a venue message to be sent as the result of an inline query.
*/
final public class InputMessageContent_Venue: InputMessageContent_Any {
	
	// The type of the input content, used for Codable.
	public static var type: InputMessageContentType = .venue
	
	/// Latitude of the venue in degrees.
	public var latitude: Float
	
	/// Longitude of the venue in degrees.
	public var longitude: Float
	
	/// Name of the venue.
	public var title: String
	
	/// Address of the venue.
	public var address: String
	
	/// Foursquare identifier of the venue, if known.
	public var foursquareID: String?
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case latitude
		case longitude
		case title
		case address
		case foursquareID = "foursquare_id"
	}
	
	init(latitude: Float, longitude: Float, title: String, address: String, foursquareID: String?) {
		self.latitude = latitude
		self.longitude = longitude
		self.title = title
		self.address = address
		self.foursquareID = foursquareID
	}
	
}
