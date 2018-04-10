//
//  GameHighScore.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/** This object represents one row of the high scores table for a game.
*/
public struct GameHighScore: Codable {
	
	/// The position in the high score table for the game.
	public var position: Int
	
	/// The user who made the score entry.
	public var user: User
	
	/// The score set.
	public var score: Int
	
	
	init(user: User, score: Int, position: Int) {
		self.user = user
		self.score = score
		self.position = position
	}

}
