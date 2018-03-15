//
//  ChosenInlineResult.swift
//  Pelican
//
//  Created by Ido Constantine on 19/12/2017.
//

import Foundation


/**
Represents a result of an inline query that was chosen by the user and sent to the chat.
*/
public struct ChosenInlineResult: UpdateModel, Codable {
	
	/// The unique identifier for the result that was chosen.
	var resultID: String
	
	/// The user that chose the result.
	var from: User
	
	/// The query that was used to obtain the result
	var query: String
	
	/// Sender location, only for bots that require user location.
	var location: Location?
	
	/// Identifier of the sent inline message. Available only if there is an inline keyboard attached to the message.
	var inlineMessageID: String?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case resultID = "inline_query_id"
		case from
		case query
		case location
		case inlineMessageID = "inline_message_id"
	}
}
