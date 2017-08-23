//
//  Request+addStickerToSet.swift
//  Pelican
//
//  Created by Lev Sokolov on 8/23/17.
//
//

import Foundation

extension TelegramRequest {
	/** Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## Function Description
	Use this method to create new sticker set owned by a user. The bot will be able to edit the created sticker set. Returns True on success.
	*/
	public static func addStickerToSet(userID: Int, name: String, pngSticker: FileLink, emojis: String, maskPosition: MaskPosition? = nil, callback: ReceiveUpload? = nil) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"user_id": userID,
			"name": name,
			"emojis": emojis
		]
		
		if let maskPosition = maskPosition {
			request.query["mask_position"] = try! maskPosition.makeRow()
		}
		
		switch pngSticker.location {
		case .stored(let id):
			request.query["png_sticker"] = id
			
		default:
			request.content = link as Any
		}
		
		// Set the Request, Method and Content
		request.methodName = "addStickerToSet"
		
		return request
	}
}
