//
//  Game.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/**
This object represents a game. Use BotFather to create and edit games, their short names will act as unique identifiers.
*/
public struct Game: Codable {
	
	/// Title of the game.
	public var title: String
	
	/// Description of the game.
	public var description: String
	
	/// Photo that will be displayed in the game message in chats.
	public var photo: [Photo]
	
	/// Brief description of the game as well as provide space for high scores.
	public var text: String?
	
	/// Special entities that appear in text, such as usernames.
	public var textEntities: [MessageEntity]?
	
	/// Animation type that will be displayed in the game message in chats.  Upload via BotFather
	public var animation: Animation?
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case title
		case description
		case photo
		case text
		case textEntities = "text_entities"
		case animation
	}
	
	
	public init(title: String,
							description: String,
							photo: [Photo],
							text: String? = nil,
							textEntities: [MessageEntity]? = nil,
							animation: Animation? = nil) {
		
		self.title = title
		self.description = description
		self.photo = photo
		self.text = text
		self.textEntities = textEntities
		self.animation = animation
	}
}
