//
//  CallbackQuery.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

/**
This object represents an incoming callback query from a callback button in an inline keyboard.

If the button that originated the query was attached to a message sent by the bot, the field message will be present. If the button was attached to a message sent via the bot (in inline mode), the field inline_message_id will be present. Exactly one of the fields data or game_short_name will be present.
*/
final public class CallbackQuery: Model, UpdateModel {
	public var storage = Storage()
	
	public var id: String								// Unique identifier for the query.
	public var from: User								// The sender of the query.
	public var message: Message?				// message with the callback button that originated from the query.  Won't be available if it's too old.
	public var inlineMessageID: String? // Identifier of the message sent via the bot in inline mode that originated the query.
	public var chatInstance: String			// Global identifier, uniquely corresponding to the chat to which the message with the callback button was sent.  Useful for high scores in games.
	public var data: String?						// Data associated with the callback button.  Be aware that a bad client can send arbitrary data here.
	public var gameShortName: String?		// Short name of a Game to be returned, serves as the unique identifier for the game.
	
	
	public init(id: String, from: User, chatInstance: String) {
		self.id = id
		self.from = from
		self.chatInstance = chatInstance
	}
	
	// NodeRepresentable conforming methods
	public required init(row: Row) throws {
		id = try row.get("id")
		from = try User(row: try row.get("from") )
		message = try Message(row: try row.get("message") )
		inlineMessageID = try row.get("inline_message_id")
		chatInstance = try row.get("chat_instance")
		data = try row.get("data")
		gameShortName = try row.get("game_short_name")
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("id", id)
		try row.set("from", from)
		try row.set("message", message)
		try row.set("inline_message_id", inlineMessageID)
		try row.set("chat_instance", chatInstance)
		try row.set("data", data)
		try row.set("game_short_name", gameShortName)
		
		return row
	}
}
