//
//  InlineResultPhoto.swift
//  Pelican
//
//  Created by Ido Constantine on 20/12/2017.
//

import Foundation


/**
Represents either a link to a photo that's stored on the Telegram servers, or an external URL link to one.

By default, this photo will be sent by the user with an optional caption. Alternatively, you can use the `content` property to send a message with the specified content instead of the file.
*/
struct InlineResultPhoto: InlineResult {
	
	/// Type of the result being given.
	public var type: String = "photo"
	
	/// Unique Identifier for the result, 1-64 bytes.
	public var id: String
	
	/// Content of the message to be sent.
	public var content: InputMessageContent?
	
	/// Inline keyboard attached to the message
	public var replyMarkup: MarkupInline?
	
	
	/// A valid URL of the photo. Photo must be in jpeg format. Photo size must not exceed 5MB
	public var url: String?
	
	/// A valid file identifier of the photo.
	public var fileID: String?
	
	/// The title of the inline result.
	public var title: String?
	
	/// A short description of the inline result.
	public var description: String?
	
	/// A caption for the photo to be sent, 200 characters maximum.
	public var caption: String?
	
	
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
		case replyMarkup = "reply_markup"
		
		case url = "photo_url"
		case fileID = "photo_file_id"
		case caption
		
		case title
		case description
		
		case thumbURL = "thumb_url"
		case thumbWidth = "thumb_width"
		case thumbHeight = "thumb_height"
	}
}
