//
//  Request+createNewStickerSet.swift
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
	public static func createNewStickerSet(userID: Int, name: String, title: String, sticker: FileLink, emojis: String, containsMasks: Bool? = nil, maskPosition: MaskPosition? = nil, callback: ReceiveUpload? = nil) -> TelegramRequest? {
		
		let request = TelegramRequest()
		
		request.query = [
			"user_id": userID,
			"name": name,
			"title": title,
			"emojis": emojis
		]
		
		switch sticker.location {
		case .stored(let id):
			request.query["png_sticker"] = id
			
		default:
			pelicanPrint("only sending with id UploadLocation is supported."); return nil
		}
		
		if let containsMasks = containsMasks {
			request.query["contains_masks"] = containsMasks
		}
		
		if let maskPosition = maskPosition {
			request.query["mask_position"] = try! maskPosition.makeRow()
		}
		
		// Set the Request, Method and Content
		request.methodName = "createNewStickerSet"
		
		return request
	}
}
