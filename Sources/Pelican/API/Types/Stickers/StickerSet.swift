//
//  StickerSet.swift
//  Pelican
//
//  Created by Ido Constantine on 21/12/2017.
//

import Foundation

/**
Represents a sticker set - a collection of stickers that are stored on the Telegram servers.
*/
public class StickerSet: Codable {
	
	/// The username for the sticker set (?)
	public var username: String
	
	/// The name of the sticker set.
	public var title: String
	
	/// If true, this set contains sticker masks.
	public var containsMasks: Bool
	
	/// An array of all the stickers that this set contains.
	public var stickers: [Sticker]
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case username = "name"
		case title
		case containsMasks = "contains_masks"
		case stickers
		
	}
	
	init(withUsername username: String, title: String, containsMasks: Bool, stickers: [Sticker]) {
		self.username = username
		self.title = title
		self.containsMasks = containsMasks
		self.stickers = stickers
	}
}
