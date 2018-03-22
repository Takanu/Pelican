//
//  InlineResultLocation.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/12/2017.
//

import Foundation

/**
Represents a location on a map. By default, the location will be sent by the user.

Alternatively, you can use `content` property to send a message with the specified content instead of the location.
*/
public struct InlineResultLocation: InlineResult {
	
	/// A metatype, used to Encode and Decode itself as part of the InlineResult protocol.
	public var metatype: InlineResultType = .location
	
	/// Type of the result being given.
	public var type: String = "location"
	
	/// Unique Identifier for the result, 1-64 bytes.
	public var id: String
	
	/// Content of the message to be sent.
	public var content: InputMessageContent?
	
	/// Inline keyboard attached to the message
	public var markup: MarkupInline?
	
	
	/// Location title.
	public var title: String
	
	/// Location latitude in degrees.
	public var latitude: Float
	
	/// Location longitude in degrees.
	public var longitude: Float
	
	
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
		case latitude
		case longitude
		
		case thumbURL = "thumb_url"
		case thumbWidth = "thumb_width"
		case thumbHeight = "thumb_height"
	}
}
