//
//  User.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/**
Represents a Telegram user or bot.
*/
public struct User: Codable {
	public let messageTypeName = "user"
	
	/// Unique identifier for the user or bot.
	public var tgID: String
	
	/// If true, this user is a bot.
	public var isBot: Bool
	
	/// User's or bot's first name.
	public var firstName: String
	
	/// User's or bot's last name.
	public var lastName: String?
	
	/// User's or bot's username.
	public var username: String?
	
	/// IETF language tag of the user's language.
	public var languageCode: String?
	
	
	enum CodingKeys: String, CodingKey {
		case tgID = "id"
		case isBot = "is_bot"
		case firstName = "first_name"
		case lastName = "last_name"
		case username = "username"
		case languageCode = "language_code"
	}
	
	public init(id: String, isBot: Bool, firstName: String) {
		self.tgID = id
		self.isBot = isBot
		self.firstName = firstName
	}
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		
		tgID = try String(values.decode(Int.self, forKey: .tgID))
		isBot = try values.decodeIfPresent(Bool.self, forKey: .isBot) ?? false
		
		firstName = try values.decode(String.self, forKey: .firstName)
		lastName = try values.decodeIfPresent(String.self, forKey: .lastName)
		username = try values.decodeIfPresent(String.self, forKey: .username)
		languageCode = try values.decodeIfPresent(String.self, forKey: .languageCode)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		let intID = Int(tgID)
		try container.encode(intID, forKey: .tgID)
		try container.encodeIfPresent(isBot, forKey: .isBot)
		try container.encode(firstName, forKey: .firstName)
		try container.encodeIfPresent(lastName, forKey: .lastName)
		try container.encodeIfPresent(username, forKey: .username)
		try container.encodeIfPresent(languageCode, forKey: .languageCode)
	}
	
}
