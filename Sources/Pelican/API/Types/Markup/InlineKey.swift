//
//  InlineKey.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

/**
Defines a single keyboard key on a `MarkupInline` keyboard.  Each key supports one of 4 different modes:
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
*/
final public class MarkupInlineKey: Model, Equatable {
	public var storage = Storage()
	
	public var text: String // Label text
	public var data: String
	public var type: InlineKeyType
	
	
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
	
	// Ignore context, just try and build an object from a node.
	public required init(row: Row) throws {
		text = try row.get("text")
		
		if row["url"] != nil {
			data = try row.get("url")
			type = .url
		}
			
		else if row["callback_data"] != nil {
			data = try row.get("callback_data")
			type = .url
		}
			
		else if row["switch_inline_query"] != nil {
			data = try row.get("switch_inline_query")
			type = .url
		}
			
		else if row["switch_inline_query_current_chat"] != nil {
			data = try row.get("switch_inline_query_current_chat")
			type = .url
		}
			
		else {
			data = ""
			type = .url
		}
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("text", text)
		
		switch type {
		case .url:
			try row.set("url", data)
		case .callbackData:
			try row.set("callback_data", data)
		case .switchInlineQuery:
			try row.set("switch_inline_query", data)
		case .switchInlineQuery_currentChat:
			try row.set("switch_inline_query_current_chat", data)
		}
		
		return row
	}
}
