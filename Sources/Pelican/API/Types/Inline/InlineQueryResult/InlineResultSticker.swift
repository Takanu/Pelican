//
//  InlineResultSticker.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/12/2017.
//

import Foundation


/**
Represents a link to a sticker stored on the Telegram servers.

By default, this sticker will be sent by the user. Alternatively, you can use the 'content' property to send a message with the specified content instead of the sticker.

Stickers can only ever be cached, you cannot currently define an external URL link to a sticker as an inline result.
*/
public struct InlineResultSticker: InlineResult {
	
	/// A metatype, used to Encode and Decode itself as part of the InlineResult protocol.
	public var metatype: InlineResultType = .sticker
	
	/// Type of the result being given.
	public var type: String = "sticker"
	
	/// Unique Identifier for the result, 1-64 bytes.
	public var id: String
	
	/// Content of the message to be sent.
	public var content: InputMessageContent?
	
	/// Inline keyboard attached to the message
	public var markup: MarkupInline?
	
	
	
	/// A valid file identifier for the sticker.
	public var fileID: String?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case type
		case id
		case content = "input_message_content"
		case markup = "reply_markup"
		
		case fileID = "sticker_file_id"
	}
}
