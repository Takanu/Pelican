//
//  InlineResultMpeg4Gif.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/12/2017.
//

import Foundation

/**
Represents either a link to a video animation (H.264/MPEG-4 AVC video without sound) stored on the Telegram servers, or an external URL link to one.

By default, this MP4 GIF will be sent by the user with an optional caption. Alternatively, you can use the `content` property to send a message with the specified content instead of the file.
*/
struct InlineResultMpeg4GIF: InlineResult {
	
	/// A metatype, used to Encode and Decode itself as part of the InlineResult protocol.
	public var metatype: InlineResultType = .mpeg4Gif
	
	/// Type of the result being given.
	public var type: String = "mpeg4_gif"
	
	/// Unique Identifier for the result, 1-64 bytes.
	public var id: String
	
	/// Content of the message to be sent.
	public var content: InputMessageContent?
	
	/// Inline keyboard attached to the message
	public var markup: MarkupInline?
	
	
	
	/// A valid URL for the MP4 file. File size must not exceed 1MB.
	public var url: String?
	
	/// A valid file identifier for the MP4 file
	public var fileID: String?
	
	/// The title of the inline result.
	public var title: String?
	
	/// A caption for the MP4 GIF to be sent, 200 characters maximum.
	public var caption: String?
	
	/// Video width.
	public var width: Int?
	
	/// Video height.
	public var height: Int?
	
	/// Video duration.
	public var duration: Int?
	
	/// URL of the static thumbnail (jpeg or gif) for the result.  This is not optional on non-cached types.
	public var thumbURL: String?
	
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case type
		case id
		case content = "input_message_content"
		case markup = "reply_markup"
		
		case url = "mpeg4_url"
		case fileID = "mpeg4_file_id"
		case title
		case caption
		
		case width = "mpeg4_width"
		case height = "mpeg4_height"
		case duration = "mpeg4_duration"
		case thumbURL = "thumb_url"
	}
}
