//
//  InlineResultDocument.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/12/2017.
//

import Foundation


/**
Represents either a link to a file stored on the Telegram servers, or an external URL link to one.

By default, this file will be sent by the user with an optional caption. Alternatively, you can use the `content` property to send a message with the specified content instead of the file.

- note: Currently, only .PDF and .ZIP files can be sent using this method.
*/
public struct InlineResultDocument: InlineResult {
	
	/// A metatype, used to Encode and Decode itself as part of the InlineResult protocol.
	public var metatype: InlineResultType = .document
	
	/// Type of the result being given.
	public var type: String = "document"
	
	/// Unique Identifier for the result, 1-64 bytes.
	public var id: String
	
	/// Content of the message to be sent.
	public var content: InputMessageContent?
	
	/// Inline keyboard attached to the message
	public var markup: MarkupInline?
	
	
	/// A valid URL of the photo. Photo must be in jpeg format. Photo size must not exceed 5MB
	public var url: String?
	
	/// A valid file identifier for the file.
	public var fileID: String?
	
	/// A caption for the document to be sent, 200 characters maximum.
	public var caption: String?
	
	/// The title of the inline result.
	public var title: String?
	
	/// A short description of the inline result.
	public var description: String?
	
	/// Mime type of the content of the file, either “application/pdf” or “application/zip”.  Not optional for un-cached results.
	var mimeType: String?
	
	
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
		
		case url = "document_url"
		case fileID = "document_file_id"
		case caption
		
		case title
		case description
		case mimeType = "mime_type"
		
		case thumbURL = "thumb_url"
		case thumbWidth = "thumb_width"
		case thumbHeight = "thumb_height"
	}
}
