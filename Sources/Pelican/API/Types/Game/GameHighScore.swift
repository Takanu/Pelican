//
//  GameHighScore.swift
//  Pelican
//
//  Created by Ido Constantine on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

/** This object represents one row of the high scores table for a game.
*/
final public class GameHighScore: Model {
	public var storage = Storage()
	
	var position: Int     // Position in the high score table for the game
	var user: User        // User who made the score entry
	var score: Int        // The score the user set
	
	
	// NodeRepresentable conforming methods
	required public init(row: Row) throws {
		position = try row.get("position")
		user = try row.get("user")
		score = try row.get("score")
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("position", position)
		try row.set("user", user)
		try row.set("score", score)
		
		return row
	}
}
