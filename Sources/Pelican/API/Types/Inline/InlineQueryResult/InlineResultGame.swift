//
//  InlineResultGame.swift
//  Pelican
//
//  Created by Ido Constantine on 20/12/2017.
//

import Foundation

/**
Represents a game.
*/
public struct InlineResultGame: InlineResult {
	
	/// Type of the result being given.
	public var type: String = "game"
	
	/// Unique Identifier for the result, 1-64 bytes.
	public var id: String
	
	/// Inline keyboard attached to the message
	public var markup: MarkupInline?
	
	/// Short name of the game.
	public var name: String
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case type
		case id
		case markup = "reply_markup"
		case name
	}
	
}
