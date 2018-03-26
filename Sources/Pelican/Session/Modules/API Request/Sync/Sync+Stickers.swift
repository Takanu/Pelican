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
	Use this method to send .webp or already uploaded stickers.
	*/
	public func sendSticker(_ sticker: Sticker, markup: MarkupType?, chatID: Int, replyID: Int = 0, disableNotification: Bool = false) {
		
		guard let request = TelegramRequest
			.sendFile(file: sticker, chatID: chatID, markup: markup, disableNotification: disableNotification)
		else {
			PLog.error("Can't create sendFile request"); return
		}
		
		guard let response = tag.sendSyncRequest(request) else { return }
		
		if false == response.success {
			PLog.error("sendSticker failed with error: \(response.responseStatus ?? ""), code: \(response.responseCode ?? "")")
		}
	}
	
	/**
	Returns a StickerSet type for the name of the sticker set given, if successful.
	*/
	public func getStickerSet(_ name: String) {
		let request = TelegramRequest.getStickerSet(name: name)
		_ = tag.sendSyncRequest(request)
	}
	
	/**
	Use this method to upload a .png file with a sticker for later use in createNewStickerSet and addStickerToSet methods (can be used multiple times).
	Returns the uploaded File on success.
	*/
	public func uploadStickerFile(_ sticker: Sticker, userID: Int) {
		guard let request = TelegramRequest.uploadStickerFile(userID: userID, sticker: sticker) else {
				PLog.error("Can't create uploadStickerFile request"); return
		}
		
		_ = tag.sendSyncRequest(request)
	}
	
	/**
	Use this method to create new sticker set owned by a user. The bot will be able to edit the created sticker set.
	*/
	public func createNewStickerSet(userID: Int, name: String, title: String, sticker: Sticker, emojis: String, containsMasks: Bool? = nil, maskPosition: MaskPosition? = nil) {
		let request = TelegramRequest.createNewStickerSet(userID: userID, name: name, title: title, sticker: sticker, emojis: emojis, containsMasks: containsMasks, maskPosition: maskPosition)
		_ = tag.sendSyncRequest(request)
	}
	
	/**
	Adds a sticker to a sticker set created by the bot.
	*/
	public func addStickerToSet(userID: Int, name: String, pngSticker: Sticker, emojis: String, maskPosition: MaskPosition? = nil) {
		let request = TelegramRequest.addStickerToSet(userID: userID, name: name, pngSticker: pngSticker, emojis: emojis, maskPosition: maskPosition)
		_ = tag.sendSyncRequest(request)
	}
	
	/**
	Use this method to move a sticker in a set created by the bot to a specific position.
	*/
	public func setStickerPositionInSet(stickerID: String, newPosition: Int) {
		let request = TelegramRequest.setStickerPositionInSet(stikerID: stickerID, position: newPosition)
		_ = tag.sendSyncRequest(request)
	}
	
	/**
	Use this method to delete a sticker from a set created by the bot.
	*/
	public func deleteStickerFromSet(stickerID: String) {
		let request = TelegramRequest.deleteStickerFromSet(stikerID: stickerID)
		_ = tag.sendSyncRequest(request)
	}
}
