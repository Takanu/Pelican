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
public enum MessageEntityType: String, Codable {
	
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
	
	case unknown
}

final public class MessageEntity: Codable {
	
	/// Type of the entity.  Can be a mention, hashtag, bot command, URL, email, special text formatting or a text mention.
	public var type: MessageEntityType
	
	/// Offset in UTF-16 code units to the start of the entity.
	public var offset: Int
	
	/// Length of the entity in UTF-16 code units.
	public var length: Int
	
	// For text links only, will be opened when the user taps on it.
	public var url: String?
	
	// For text mentions only, the mentioned user.
	public var user: User?
	
	enum CodingKeys: String, CodingKey {
		case type
		case offset
		case length
		case url
		case user
	}
	
	
	public init(type: MessageEntityType, offset: Int, length: Int) {
		self.type = type
		self.offset = offset
		self.length = length
	}
	
	/**
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		
		let typeString = try values.decode(String.self, forKey: .type)
		type = MessageEntityType(rawValue: typeString.snakeToCamelCase) ?? .unknown
	
		offset = try values.decode(Int.self, forKey: .type)
		length = try values.decode(Int.self, forKey: .length)
		url = try values.decode(String.self, forKey: .url)
		user = try values.decode(User.self, forKey: .user)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(type.rawValue, forKey: .type)
		try container.encode(offset, forKey: .offset)
		try container.encode(length, forKey: .length)
		try container.encode(url, forKey: .url)
		try container.encode(user, forKey: .user)
	}
	*/
	
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
}
