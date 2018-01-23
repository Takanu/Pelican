//
//  InlineResultGif.swift
//  Pelican
//
//  Created by Ido Constantine on 20/12/2017.
//

import Foundation

/**
Represents either a link to an animated GIF stored on the Telegram servers, or an external URL link to one.

By default, this GIF will be sent by the user with an optional caption. Alternatively, you can use the `content` property to send a message with the specified content instead of the file.
*/
struct InlineResultGIF: InlineResult {
	
	/// A metatype, used to Encode and Decode itself as part of the InlineResult protocol.
	public var metatype: InlineResultType = .gif
	
	// Type of the result being given.
	var type: String = "gif"
	
	// Unique Identifier for the result, 1-64 bytes.
	var id: String
	
	// Content of the message to be sent.
	var content: InputMessageContent?
	
	// Inline keyboard attached to the message
	var markup: MarkupInline?
	
	/// The title of the inline result.
	var title: String?
	
	
	
	/// A valid URL for the GIF file. File size must not exceed 1MB.
	var url: String?
	
	/// A file id for the inline result.  Won't be used if the inline result is represented by a URL instead.
	var fileID: String?
	
	// A caption for the GIF to be sent, 200 characters maximum.
	var caption: String?
	
	// Width of the GIF.
	var width: Int?
	
	// Height of the GIF.
	var height: Int?
	
	/// Duration of the GIF.
	var duration: Int?
	
	// URL of the static thumbnail for the result (JPEG or GIF).  This is not optional on non-cached types.
	var thumbURL: String?
	
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case type
		case id
		case content = "input_message_content"
		case markup = "reply_markup"
		case title
		
		case url = "mpeg4_url"
		case fileID = "gif_file_id"
		case caption
		
		case width = "gif_width"
		case height = "gif_height"
		case duration = "gif_duration"
		case thumbURL = "thumb_url"
	}
	
}
