//
//  InputMessageText.swift
//  Pelican
//
//  Created by Ido Constantine on 19/12/2017.
//

import Foundation

/**
Represents the content of a text message to be sent as the result of an inline query.
*/
final public class InputMessageContent_Text: InputMessageContent_Any {
	
	// The type of the input content, used for Codable.
	public static var type: InputMessageContentType = .text
	
	/// Text of the message to be sent.  1-4096 characters.
	public var text: String
	
	/// Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in your bot's message.
	public var parseMode: String?
	
	/// Disables link previews for links in the sent message.
	public var disableWebPreview: Bool?
	
	init(text: String, parseMode: String?, disableWebPreview: Bool?) {
		self.text = text
		self.parseMode = parseMode
		self.disableWebPreview = disableWebPreview
	}
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case text = "message_text"
		case parseMode = "parse_mode"
		case disableWebPreview = "disable_web_page_preview"
	}
	
}
