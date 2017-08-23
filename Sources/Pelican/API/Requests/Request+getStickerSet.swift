//
//  Request+getStickerSet.swift
//  Pelican
//
//  Created by Lev Sokolov on 8/23/17.
//
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
		request.methodName = "getStickerSet"
		
		return request
	}
}
