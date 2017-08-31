//
//  Game.swift
//  Pelican
//
//  Created by Ido Constantine on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

/** This object represents a game. Use BotFather to create and edit games, their short names will act as unique identifiers.
*/
final public class Game: Model {
	public var storage = Storage()
	
	public var title: String                 // Title of the game
	public var description: String           // Description of the game
	public var photo: [PhotoSize]            // Photo that will be displayed in the game message in chats.
	public var text: String?                 // Brief description of the game as well as provide space for high scores.
	public var textEntries: [MessageEntity]? // Special entities that appear in text, such as usernames.
	public var animation: String?            // Animation type that will be displayed in the game message in chats.  Upload via BotFather
	
	
	// NodeRepresentable conforming methods
	required public init(row: Row) throws {
		title = try row.get("title")
		description = try row.get("description")
		photo = try row.get("photo")
		text = try row.get("text")
		textEntries = try row.get("text_entities")
		animation = try row.get("animation")
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("title", title)
		try row.set("description", description)
		try row.set("photo", photo)
		try row.set("text", text)
		try row.set("text_entities", textEntries)
		try row.set("animation", animation)
		
		return row
	}
}
