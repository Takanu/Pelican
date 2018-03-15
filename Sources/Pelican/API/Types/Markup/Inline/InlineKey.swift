//
//  InlineKey.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/**
Defines a single keyboard key on a `MarkupInline` keyboard.  Each key supports one of 6 different modes:
_ _ _ _ _

**Callback Data**

This sends a small String back to the bot as a `CallbackQuery`, which is automatically filtered
back to the session and to a `callbackState` if one exists.

Alternatively if the keyboard the button belongs to is part of a `Prompt`, it will automatically
be received by it in the respective ChatSession, and the prompt will respond based on how you have set
it up.

**URL**

The button when pressed will re-direct users to a webpage.

**Inine Query Switch**

This can only be used when the bot supports Inline Queries.  This prompts the user to select one of their chats
to open it, and when open the client will insert the bot‘s username and a specified query in the input field.

**Inline Query Current Chat**

This can only be used when the bot supports Inline Queries.  Pressing the button will insert the bot‘s username
and an optional specific inline query in the current chat's input field.

**Callback Game**

This button will contain a description of the game that will be launched when the user presses the button.  **This button must be the first one on the first row** in order to work.

**Payment Button**

This button will allow the user to pay for something.  **This only appears when using the sendInvoice method, and cannot be sent to Telegram as part of a different request.**  This button is always the first button in the first row.

*/
final public class MarkupInlineKey: Codable, Equatable {
	
	public var text: String // Label text
	public var data: String
	public var type: InlineKeyType
	public var isPayButton: Bool = false
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case text
		
		case url
		case callbackData = "callback_data"
		case switchInlineQuery = "switch_inline_query"
		case switchInlineQuery_currentChat = "switch_inline_query_current_chat"
		case callbackGame = "callback_game"
		case payButton = "pay"
	}
	
	public init(from decoder: Decoder) throws {
		
		let values = try decoder.container(keyedBy: CodingKeys.self)
		text = try values.decode(String.self, forKey: .text)
		
		let keys = values.allKeys
		if keys.contains(.url) {
			data = try values.decode(String.self, forKey: .url)
			type = .url
		}
		
		else if keys.contains(.callbackData) {
			data = try values.decode(String.self, forKey: .callbackData)
			type = .callbackData
		}
		
		else if keys.contains(.switchInlineQuery) {
			data = try values.decode(String.self, forKey: .switchInlineQuery)
			type = .switchInlineQuery
		}
		
		else if keys.contains(.switchInlineQuery_currentChat) {
			data = try values.decode(String.self, forKey: .switchInlineQuery_currentChat)
			type = .switchInlineQuery_currentChat
		}
		
		else if keys.contains(.callbackGame) {
			data = try values.decode(String.self, forKey: .callbackGame)
			type = .callbackGame
		}
		
		else if keys.contains(.payButton){
			isPayButton = true
			data = ""
			type = .payButton
		}
		
		else {
			PLog.error("The MarkupKey with the text label, \"\(String(describing:text))\" has an invalid data type.")
			data = ""
			type = .unknown
		}
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(text, forKey: .text)
		
		if type == .url {
			try container.encode(data, forKey: .url)
		}
		
		else if type == .callbackData {
			try container.encode(data, forKey: .callbackData)
		}
		
		else if type == .switchInlineQuery {
			try container.encode(data, forKey: .switchInlineQuery)
		}
		
		else if type == .switchInlineQuery_currentChat {
			try container.encode(data, forKey: .switchInlineQuery_currentChat)
		}
			
		else if type == .callbackGame {
			try container.encode(data, forKey: .callbackGame)
		}
			
		else if type == .payButton {
			try container.encode(isPayButton, forKey: .payButton)
		}
		
		// If the type was unknown and this is about to be encoded for use in an API request, it should be made very clear that this is bugged.
		else {
			
			try container.encode("<Data Type Error>", forKey: .text)
			try container.encode("<Data Type Error>", forKey: .callbackData)
		}
	}
	
	/**
	Creates a `MarkupInlineKey` as a URL key.
	
	This key type causes the specified URL to be opened by the client
	when button is pressed.  If it links to a public Telegram chat or bot, it will be immediately opened.
	*/
	public init(fromURL url: String, text: String) {
		self.text = text
		self.data = url
		self.type = .url
	}
	
	/**
	Creates a `MarkupInlineKey` as a Callback Data key.
	
	This key sends the defined callback data back to the bot to be handled.
	
	- parameter callback: The data to be sent back to the bot once pressed.  Accepts 1-64 bytes of data.
	- parameter text: The text label to be shown on the button.  Set to nil if you wish it to be the same as the callback.
	*/
	public init?(fromCallbackData callback: String, text: String?) {
		
		// Check to see if the callback meets the byte requirement.
		if callback.lengthOfBytes(using: String.Encoding.utf8) > 64 {
			PLog.error("The MarkupKey with the text label, \"\(String(describing:text))\" has a callback of \(callback) that exceeded 64 bytes.")
			return nil
		}
		
		// Check to see if we have a label
		if text != nil { self.text = text! }
		else { self.text = callback }
		
		self.data = callback
		self.type = .callbackData
	}
	
	/**
	Creates a `MarkupInlineKey` as a Current Chat Inline Query key.
	
	This key prompts the user to select one of their chats, open it and insert the bot‘s username and the specified query in the input field.
	*/
	public init(fromInlineQueryCurrent data: String, text: String) {
		self.text = text
		self.data = data
		self.type = .switchInlineQuery_currentChat
	}
	
	/**
	Creates a `MarkupInlineKey` as a New Chat Inline Query key.
	
	This key inserts the bot‘s username and the specified inline query in the current chat's input field.  Can be empty.
	*/
	public init(fromInlineQueryNewChat data: String, text: String) {
		self.text = text
		self.data = data
		self.type = .switchInlineQuery
	}
	
	static public func ==(lhs: MarkupInlineKey, rhs: MarkupInlineKey) -> Bool {
		
		if lhs.text != rhs.text { return false }
		if lhs.type != rhs.type { return false }
		if lhs.data != rhs.data { return false }
		
		return true
	}
	
	
}
