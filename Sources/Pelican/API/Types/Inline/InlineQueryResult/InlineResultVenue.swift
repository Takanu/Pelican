//
//  InlineResultVenue.swift
//  Pelican
//
//  Created by Ido Constantine on 20/12/2017.
//

import Foundation

/**
Represents a venue. By default, the venue will be sent by the user.

Alternatively, you can use the `content` property to send a message with the specified content instead of the venue.
*/
public struct InlineResultVenue: InlineResult {
	
	/// Type of the result being given.
	public var type: String = "venue"
	
	/// Unique Identifier for the result, 1-64 bytes.
	public var id: String
	
	/// Content of the message to be sent.
	public var content: InputMessageContent?
	
	/// Inline keyboard attached to the message
	public var markup: MarkupInline?
	
	
	
	/// Location title.
	public var title: String
	
	/// Address of the venue.
	public var address: String
	
	/// Location latitude in degrees.
	public var latitude: Float
	
	/// Location longitude in degrees.
	public var longitude: Float
	
	/// Foursquare identifier of the venue if known.
	public var foursquareID: String?
	
	
	/// URL of the thumbnail to use for the result.
	public var thumbURL: String?
	
	/// Thumbnail width.
	public var thumbWidth: Int?
	
	/// Thumbnail height.
	public var thumbHeight: Int?
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case type
		case id
		case content = "input_message_content"
		case markup = "reply_markup"
		
		case title
		case address
		case latitude
		case longitude
		case foursquareID = "foursquare_id"
		
		case thumbURL = "thumb_url"
		case thumbWidth = "thumb_width"
		case thumbHeight = "thumb_height"
	}
}
