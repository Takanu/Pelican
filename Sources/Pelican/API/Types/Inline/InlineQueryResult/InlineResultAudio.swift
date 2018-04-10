//
//  InlineResultAudio.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/12/2017.
//

import Foundation

/**
Represents either a link to a MP3 audio file stored on the Telegram servers, or an external URL link to one.
*/
public struct InlineResultAudio: InlineResult {
	
	/// A metatype, used to Encode and Decode itself as part of the InlineResult protocol.
	public var metatype: InlineResultType = .audio
	
	// Type of the result being given.
	public var type: String = "audio"
	
	// Unique Identifier for the result, 1-64 bytes.
	var id: String
	
	// Content of the message to be sent.
	var content: InputMessageContent?
	
	// Inline keyboard attached to the message
	var markup: MarkupInline?
	
	
	
	// A valid URL for the audio file.
	var url: String?
	
	/// A valid file identifier for the audio file.
	var fileID: String?
	
	/// A caption for the Audio file to be sent, 200 characters maximum.
	var caption: String?
	
	/// Title.
	var title: String?
	
	/// Performer.
	var performer: String?
	
	/// Audio duration in seconds.
	var duration: Int?
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case type
		case id
		case content = "input_message_content"
		case markup = "reply_markup"
		
		case url = "audio_url"
		case fileID = "audio_file_id"
		
		case caption
		case title
		case performer
		case duration = "audio_duration"
	}
		
}
