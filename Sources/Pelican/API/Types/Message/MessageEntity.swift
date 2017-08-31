//
//  MessageEntity.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

/// Represents one special entity in a text message, such as a hashtag, username or URL.
public enum MessageEntityType: String {
	
	case mention
	case hashtag
	case botCommand
	case url
	case email
	case textLink
	case textMention
	
	case bold
	case italic
	case code
	case pre
}

final public class MessageEntity: Model {
	public var storage = Storage()
	public var type: MessageEntityType // Type of the entity.  Can be a mention, hashtag, bot command, URL, email, special text formatting or a text mention.
	public var offset: Int // Offset in UTF-16 code units to the start of the entity.
	public var length: Int // Length of the entity in UTF-16 code units.
	public var url: String? // For text links only, will be opened when the user taps on it.
	public var user: User? // For text mentions only, the mentioned user.
	
	
	public init(type: MessageEntityType, offset: Int, length: Int) {
		self.type = type
		self.offset = offset
		self.length = length
	}
	
	/**
	Extracts the piece of text it represents from the message body.
	- returns: The string of the entity if successful, and nil if not.
	*/
	public func extract(fromMessage message: Message) -> String? {
		
		if message.text == nil { return nil }
		let text = message.text!
		
		let encoded = text.utf16
		let encStart = encoded.index(encoded.startIndex, offsetBy: offset)
		let encEnd = encoded.index(encStart, offsetBy: length)
		
		let stringBody = encoded.prefix(upTo: encEnd)
		let finalString = stringBody.suffix(from: encStart)
		
		return String(finalString)
		
	}
	
	// NodeRepresentable conforming methods
	public required init(row: Row) throws {
		type = MessageEntityType(rawValue: row["type"]!.string!.snakeToCamelCase)!
		offset = try row.get("offset")
		length = try row.get("length")
		url = try row.get("url")
		user = try row.get("user")
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("type", type)
		try row.set("offset", offset)
		try row.set("length", length)
		try row.set("url", url)
		try row.set("user", user)
		
		return row
	}
}
