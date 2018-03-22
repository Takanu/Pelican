//
//  SessionRequest+Stickers.swift
//  Pelican
//
//  Created by Takanu Kyriako on 17/12/2017.
//

import Foundation

/**
This extension handles any kinds of operations involving stickers (including setting group sticker packs).
*/
extension SessionRequestSync {
	
	/**
	Use this method to send .webp stickers. (COMBINE WITH SENDFILE, just makes sense tbh).
	*/
	public func sendSticker(_ stickerFIXME: String,
													markup: MarkupType?,
													chatID: Int,
													replyID: Int = 0,
													disableNotification: Bool = false) {
		
	}
	
	/**
	Returns a StickerSet type for the name of the sticker set given, if successful.
	*/
	public func getStickerSet(_ name: String) {
		
	}
	
	/**
	Use this method to upload a .png file with a sticker for later use in createNewStickerSet and addStickerToSet methods (can be used multiple times).
	Returns the uploaded File on success.
	*/
	public func uploadStickerFile(_ stickerFIXME: String, chatID: Int) {
		
	}
	
	/**
	Use this method to create new sticker set owned by a user. The bot will be able to edit the created sticker set.
	*/
	public func createNewStickerSet(name: String,
																	title: String,
																	image: Photo,
																	emojis: String,
																	userID: String,
																	doesContainMasks: Bool = false,
																	maskPositionFIXME: Int?) {
		
		
	}
	
	/**
	Adds a sticker to a sticker set created by the bot.
	- returns: True on success.
	*/
	public func addStickerToSet(name: String,
															image: Photo,
															emojis: String,
															userID: String,
															maskPositionFIXME: Int?) {
		
	}
	
	/**
	Use this method to move a sticker in a set created by the bot to a specific position.
	- returns: True on success.
	*/
	public func setStickerPositionInSet(stickerID: String, newPosition: Int) {
		
	}
	
	/**
	Use this method to delete a sticker from a set created by the bot.
	- returns: True on success.
	*/
	public func deleteStickerFromSet(stickerID: String) {
		
	}
	
}
