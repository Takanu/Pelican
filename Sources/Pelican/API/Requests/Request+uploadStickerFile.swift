//
//  Request+uploadStickerFile.swift
//  Pelican
//
//  Created by Lev Sokolov on 8/23/17.
//
//

import Foundation

extension TelegramRequest {
	/** Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## Function Description
	Use this method to upload a .png file with a sticker for later use in createNewStickerSet and addStickerToSet methods (can be used multiple times). Returns the uploaded File on success.
	*/
	public static func uploadStickerFile(userID: Int, link: FileLink, callback: ReceiveUpload? = nil) -> TelegramRequest? {
		
		let request = TelegramRequest()
		
		request.query = [
			"user_id": userID
		]
		
		switch link.location {
		case .stored:
			pelicanPrint("Sending by file id isn't available."); return nil
			
		default:
			request.content = link as Any
		}
		
		// Set the Request, Method and Content
		request.methodName = link.type.method
		
		return request
	}
}
