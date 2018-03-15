//
//  Request+setStickerPositionInSet.swift
//  Pelican
//
//  Created by Lev Sokolov on 8/23/17.
//
//

import Foundation

extension TelegramRequest {
	/** Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## Function Description
	Use this method to move a sticker in a set created by the bot to a specific position . Returns True on success.
	*/
	public static func setStickerPositionInSet(stikerID: String, position: Int) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"stiker": stikerID,
			"position": position
		]
		
		// Set the Request, Method and Content
		request.methodName = "setStickerPositionInSet"
		
		return request
	}
}
