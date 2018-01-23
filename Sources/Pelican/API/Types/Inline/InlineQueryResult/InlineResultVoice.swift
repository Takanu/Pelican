//
//  InlineResultVoice.swift
//  Pelican
//
//  Created by Ido Constantine on 20/12/2017.
//

import Foundation


/**
Represents either a link to a voice recording in an .ogg container encoded with OPUS that's stored on the Telegram servers, or an external URL link to one.

By default, this voice recording will be sent by the user. Alternatively, you can use the `content` property to send a message with the specified content instead of the the voice message.
*/
struct InlineResultVoice: InlineResult {
	
	/// A metatype, used to Encode and Decode itself as part of the InlineResult protocol.
	public var metatype: InlineResultType = .voice
	
	/// Type of the result being given.
	public var type: String = "voice"
	
	/// Unique Identifier for the result, 1-64 bytes.
	public var id: String
	
	/// Content of the message to be sent.
	public var content: InputMessageContent?
	
	/// Inline keyboard attached to the message
	public var markup: MarkupInline?
	
	
	/// A valid URL for the voice recording or .ogg file encoded with OPUS.
	public var url: String?
	
	/// A valid file identifier for the file.
	public var fileID: String?
	
	/// A caption for the audio file to be sent, 200 characters maximum.
	public var caption: String?
	
	/// The title of the inline result.
	public var title: String?
	
	/// Recording duration in seconds.
	public var duration: Int?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case type
		case id
		case content = "input_message_content"
		case markup = "reply_markup"
		
		case url = "voice_url"
		case fileID = "voice_file_id"
		case caption
		
		case title
		case duration
	}
}

