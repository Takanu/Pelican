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
	Returns a StickerSet type for the name of the sticker set given, if successful.
	*/
	public func getStickerSet(_ name: String) -> StickerSet? {
		
		let request = TelegramRequest.getStickerSet(name: name)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response)
	}
	
	/**
	Use this method to upload a .png file with a sticker for later use in createNewStickerSet and addStickerToSet
	methods (can be used multiple times).
	*/
	public func uploadStickerFile(_ sticker: Sticker, userID: Int) -> FileDownload? {
		
		guard let request = TelegramRequest.uploadStickerFile(userID: userID, sticker: sticker) else {
				PLog.error("Can't create uploadStickerFile request.")
			return nil
		}
		
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response)
	}
	
	/**
	Use this method to create new sticker set owned by a user. The bot will be able to edit the created sticker set.
	*/
	@discardableResult
	public func createNewStickerSet(userID: Int,
																	name: String,
																	title: String,
																	sticker: Sticker,
																	emojis: String,
																	containsMasks: Bool? = nil,
																	maskPosition: MaskPosition? = nil) -> Bool {
		
		let request = TelegramRequest.createNewStickerSet(userID: userID,
																											name: name,
																											title: title,
																											sticker: sticker,
																											emojis: emojis,
																											containsMasks: containsMasks,
																											maskPosition: maskPosition)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response) ?? false
	}
	
	/**
	Adds a sticker to a sticker set created by the bot.
	*/
	@discardableResult
	public func addStickerToSet(userID: Int,
															name: String,
															pngSticker: Sticker,
															emojis: String,
															maskPosition: MaskPosition? = nil) -> Bool {
		
		let request = TelegramRequest.addStickerToSet(userID: userID, name: name, pngSticker: pngSticker, emojis: emojis, maskPosition: maskPosition)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response) ?? false
	}
	
	/**
	Use this method to move a sticker in a set created by the bot to a specific position.
	*/
	public func setStickerPositionInSet(stickerID: String, newPosition: Int) -> Bool {
		
		let request = TelegramRequest.setStickerPositionInSet(stickerID: stickerID, position: newPosition)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response) ?? false
	}
	
	/**
	Use this method to delete a sticker from a set created by the bot.
	*/
	public func deleteStickerFromSet(stickerID: String) -> Bool {
		
		let request = TelegramRequest.deleteStickerFromSet(stickerID: stickerID)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response) ?? false
	}
}
