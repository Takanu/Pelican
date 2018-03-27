//
//  Async+Stickers.swift
//  Pelican
//
//  Created by Ido Constantine on 27/03/2018.
//

import Foundation

extension SessionRequestAsync {
	
	/**
	Returns a StickerSet type for the name of the sticker set given, if successful.
	*/
	public func getStickerSet(_ name: String, callback: ((StickerSet?) -> ())? ) {
		
		let request = TelegramRequest.getStickerSet(name: name)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(SessionRequest.decodeResponse(nil))
			}
		}
	}
	
	/**
	Use this method to upload a .png file with a sticker for later use in createNewStickerSet and addStickerToSet
	methods (can be used multiple times).
	*/
	public func uploadStickerFile(_ sticker: Sticker, userID: Int, callback: ((FileDownload?) -> ())? ) {
		
		guard let request = TelegramRequest.uploadStickerFile(userID: userID, sticker: sticker) else {
			PLog.error("Can't create uploadStickerFile request.")
				
				if callback != nil {
					callback!(nil)
				}
			return
		}
		
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(SessionRequest.decodeResponse(response))
			}
		}
	}
	
	/**
	Use this method to create new sticker set owned by a user. The bot will be able to edit the created sticker set.
	*/
	public func createNewStickerSet(userID: Int,
																	name: String,
																	title: String,
																	sticker: Sticker,
																	emojis: String,
																	containsMasks: Bool? = nil,
																	maskPosition: MaskPosition? = nil,
																	callback: CallbackBoolean) {
		
		let request = TelegramRequest.createNewStickerSet(userID: userID,
																											name: name,
																											title: title,
																											sticker: sticker,
																											emojis: emojis,
																											containsMasks: containsMasks,
																											maskPosition: maskPosition)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(SessionRequest.decodeResponse(response) ?? false)
			}
		}
	}
	
	/**
	Adds a sticker to a sticker set created by the bot.
	*/
	public func addStickerToSet(userID: Int,
															name: String,
															pngSticker: Sticker,
															emojis: String,
															maskPosition: MaskPosition? = nil,
															callback: CallbackBoolean) {
		
		let request = TelegramRequest.addStickerToSet(userID: userID, name: name, pngSticker: pngSticker, emojis: emojis, maskPosition: maskPosition)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(SessionRequest.decodeResponse(response) ?? false)
			}
		}
	}
	
	/**
	Use this method to move a sticker in a set created by the bot to a specific position.
	*/
	public func setStickerPositionInSet(stickerID: String, newPosition: Int, callback: CallbackBoolean) {
		
		let request = TelegramRequest.setStickerPositionInSet(stickerID: stickerID, position: newPosition)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(SessionRequest.decodeResponse(response) ?? false)
			}
		}
	}
	
	/**
	Use this method to delete a sticker from a set created by the bot.
	*/
	public func deleteStickerFromSet(stickerID: String, callback: CallbackBoolean) {
		
		let request = TelegramRequest.deleteStickerFromSet(stickerID: stickerID)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(SessionRequest.decodeResponse(response) ?? false)
			}
		}
	}
	
}
