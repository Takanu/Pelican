//
//  Request+deleteStickerFromSet.swift
//  Pelican
//
//  Created by Lev Sokolov on 8/23/17.
//
//

import Foundation

extension TelegramRequest {
	/** Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## Function Description
	Use this method to delete a sticker from a set created by the bot. Returns True on success.
	*/
	public static func deleteStickerFromSet(stikerID: String) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"stiker": stikerID
		]
		
		// Set the Request, Method and Content
		request.methodName = "deleteStickerFromSet"
		
		return request
	}
}
