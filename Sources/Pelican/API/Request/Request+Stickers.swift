//
//  Request+Stickers.swift
//  Pelican
//
//  Created by Lev Sokolov on 3/24/18.
//

import Foundation

extension TelegramRequest {
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	- Parameter name: Name of the sticker set
	
	## API Description
	Use this method to get a sticker set. On success, a `StickerSet` object is returned.
	*/
	public static func getStickerSet(name: String) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"name": name
		]
		
		// Set the Request, Method and Content
		request.method = "getStickerSet"
		
		return request
	}
	
	/** Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## Function Description
	Use this method to create new sticker set owned by a user. The bot will be able to edit the created sticker set. Returns True on success.
	*/
	public static func addStickerToSet(userID: String,
																		 name: String,
																		 pngSticker: Sticker,
																		 emojis: String,
																		 maskPosition: MaskPosition? = nil) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"user_id": Int(userID),
			"name": name,
			"emojis": emojis
		]
		
		if let maskPosition = maskPosition {
			if let encodedMaskPosition = TelegramRequest.encodeDataToUTF8(maskPosition) {
				request.query["mask_position"] = encodedMaskPosition
			}
		}
		
		if let fileID = pngSticker.fileID {
			request.query["file_id"] = fileID
		}
		else {
			request.content = pngSticker as Any
		}
		
		request.content = pngSticker
		
		// Set the Request, Method and Content
		request.method = "addStickerToSet"
		
		return request
	}
	
	/** Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## Function Description
	Use this method to create new sticker set owned by a user. The bot will be able to edit the created sticker set. Returns True on success.
	*/
	public static func createNewStickerSet(userID: String,
																				 name: String,
																				 title: String,
																				 sticker: Sticker,
																				 emojis: String,
																				 containsMasks: Bool? = nil,
																				 maskPosition: MaskPosition? = nil) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"user_id": Int(userID),
			"name": name,
			"title": title,
			"emojis": emojis
		]
		
		if let fileID = sticker.fileID {
			request.query["file_id"] = fileID
		}
		else {
			request.content = sticker as Any
		}
		
		if let containsMasks = containsMasks {
			request.query["contains_masks"] = containsMasks
		}
		
		if let maskPosition = maskPosition {
			if let encodedMaskPosition = TelegramRequest.encodeDataToUTF8(maskPosition) {
				request.query["mask_position"] = encodedMaskPosition
			}
		}
		
		// Set the Request, Method and Content
		request.method = "createNewStickerSet"
		
		return request
	}
	
	/** Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## Function Description
	Use this method to delete a sticker from a set created by the bot. Returns True on success.
	*/
	public static func deleteStickerFromSet(stickerID: String) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"sticker": stickerID
		]
		
		// Set the Request, Method and Content
		request.method = "deleteStickerFromSet"
		
		return request
	}
	
	/** Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## Function Description
	Use this method to move a sticker in a set created by the bot to a specific position . Returns True on success.
	*/
	public static func setStickerPositionInSet(stickerID: String, position: Int) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"sticker": stickerID,
			"position": position
		]
		
		// Set the Request, Method and Content
		request.method = "setStickerPositionInSet"
		
		return request
	}
	
	/** Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## Function Description
	Use this method to upload a .png file with a sticker for later use in createNewStickerSet and addStickerToSet methods (can be used multiple times). Returns the uploaded File on success.
	*/
	public static func uploadStickerFile(userID: String, sticker: Sticker) -> TelegramRequest? {
		
		let request = TelegramRequest()
		
		request.query = [
			"user_id": Int(userID)
		]
		
		guard sticker.fileID == nil else {
			PLog.error("Uploading sticker by fileID isn't available."); return nil
		}
		
		request.content = sticker as Any
		
		// Set the Request, Method and Content
		request.method = sticker.method
		
		return request
	}
}
