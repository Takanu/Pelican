//
//  Keyboard+Actions.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

/**
Represents a special action that when sent with a message, will remove any `MarkupKeyboard`
currently active, for either all of or a specified group of users.
*/
final public class MarkupKeyboardRemove: Model, MarkupType {
	public var storage = Storage()
	
	/// Requests clients to remove the custom keyboard (user will not be able to summon this keyboard)
	var removeKeyboard: Bool = true
	/// (Optional) Use this parameter if you want to remove the keyboard from specific users only.
	public var selective: Bool = false
	
	
	/**
	Creates a `MarkupKeyboardRemove` instance, to remove an active `MarkupKeyboard` from the current chat.
	
	If isSelective is true, the keyboard will only be removed for the targets of the message.
	
	**Targets:**
	1) users that are @mentioned in the text of the Message object;
	2) if the bot's message is a reply (has reply_to_message_id), sender of the original message.
	
	- parameter isSelective: If false, the keyboard will be removed for all users.  If true however, the
	keyboard will only be cleared for the targets you specify.
	*/
	public init(isSelective sel: Bool) {
		selective = sel
	}
	
	// Ignore context, just try and build an object from a node.
	public required init(row: Row) throws {
		removeKeyboard = try row.get("remove_keyboard")
		selective = try row.get("selective")
		
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("remove_keyboard", removeKeyboard)
		try row.set("selective", selective)
		
		return row
	}
	
}

/**
Represents a special action that when sent with a message, will force Telegram clients to display
a reply interface to all or a selected group of people in the chat.
*/
final public class MarkupForceReply: Model, MarkupType {
	public var storage = Storage()
	
	/// Shows reply interface to the user, as if they manually selected the bot‘s message and tapped ’Reply'
	public var forceReply: Bool = true
	/// (Optional) Use this parameter if you want to force reply from specific users only.
	public var selective: Bool = false
	
	/**
	Creates a `MarkupForceReply` instance, to force Telegram clients to display
	a reply interface to all or a selected group of people in the chat.
	
	If isSelective is true, the reply interface will only be displayed to targets of the message it is being sent with.
	
	**Targets:**
	1) users that are @mentioned in the text of the Message object;
	2) if the bot's message is a reply (has reply_to_message_id), sender of the original message.
	
	- parameter isSelective: If false, the reply interface will appear for all users.  If true however, the
	reply interface will only appear for the targets you specify.
	*/
	public init(isSelective sel: Bool) {
		selective = sel
	}
	
	// Ignore context, just try and build an object from a node.
	public required init(row: Row) throws {
		forceReply = try row.get("force_reply")
		selective = try row.get("selective")
		
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("force_reply", forceReply)
		try row.set("selective", selective)
		
		return row
	}
}
