//
//  CallbackQuery.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/**
This object represents an incoming callback query from a callback button in an inline keyboard.

If the button that originated the query was attached to a message sent by the bot, the field message will be present. If the button was attached to a message sent via the bot (in inline mode), the field inline_message_id will be present. Exactly one of the fields data or game_short_name will be present.
*/
final public class CallbackQuery: UpdateModel {
	
	/// Unique identifier for the query.
	public var id: String
	
	/// The sender of the query.
	public var from: User
	
	/// Message with the callback button that originated from the query.  This will not be available if it's too old.
	public var message: Message?
	
	/// Global identifier, uniquely corresponding to the chat to which the message with the callback button was sent.  Useful for high scores in games.
	public var chatInstance: String
	
	/// Identifier of the message sent via the bot in inline mode that originated the query.
	public var inlineMessageID: String?
	
	/// Data associated with the callback button.  Be aware that a bad client can send arbitrary data here.
	public var data: String?
	
	/// Short name of a Game to be returned, serves as the unique identifier for the game.
	public var gameShortName: String?
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case id
		case from
		case message
		case inlineMessageID = "inline_message_id"
		case chatInstance = "chat_instance"
		case data
		case gameShortName = "game_short_name"
	}
	
	
	public init(id: String,
							from: User,
							messahe: Message? = nil,
							chatInstance: String,
							inlineMessageID: String? = nil,
							data: String? = nil,
							gameShortName: String? = nil) {
		
		self.id = id
		self.from = from
		self.chatInstance = chatInstance
	}

}
