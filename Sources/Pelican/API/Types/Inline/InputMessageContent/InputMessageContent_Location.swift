//
//  InputMessageLocation.swift
//  Pelican
//
//  Created by Takanu Kyriako on 19/12/2017.
//

import Foundation

/**
Represents the content of a location message to be sent as the result of an inline query.
*/
public struct InputMessageContent_Location: InputMessageContent_Any {
	
	// The type of the input content, used for Codable.
	public static var type: InputMessageContentType = .location
	
	/// Latitude of the venue in degrees.
	public var latitude: Float
	
	/// Longitude of the venue in degrees.
	public var longitude: Float
	
	/// Period in seconds for which the location can be updated, should be between 60 and 86400 seconds.  (Used for Live Locations).
	public var livePeriod: Int?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case latitude
		case longitude
		case livePeriod = "live_period"
	}
	
	init(latitude: Float, longitude: Float, livePeriod: Int?) {
		self.latitude = latitude
		self.longitude = longitude
		self.livePeriod = livePeriod
	}
}
