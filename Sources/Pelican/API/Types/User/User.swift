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
final public class User: Codable {
	public var messageTypeName = "user"
	
	/// Unique identifier for the user or bot.
	public var tgID: Int
	
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
	
	public init(id: Int, isBot: Bool, firstName: String) {
		self.tgID = id
		self.isBot = isBot
		self.firstName = firstName
	}
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		
		tgID = try values.decode(Int.self, forKey: .tgID)
		
		let botValue = try values.decode(Int.self, forKey: .isBot)
		if botValue <= 0 {
			isBot = false
		} else {
			isBot = true
		}
		
		firstName = try values.decode(String.self, forKey: .firstName)
		lastName = try values.decodeIfPresent(String.self, forKey: .lastName)
		username = try values.decodeIfPresent(String.self, forKey: .username)
		languageCode = try values.decodeIfPresent(String.self, forKey: .languageCode)
	}
	
	
	
	
	
}
