//
//  Request+sendSticker.swift
//  Pelican
//
//  Created by Lev Sokolov on 8/23/2017.
//
//

import Foundation

extension TelegramRequest {
	
	/** Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## Function Description
	Use this method to send .webp stickers. On success, the sent Message is returned.
	*/
	public static func sendSticker(chatID: Int, sticker: FileLink, disableNtf: Bool? = nil,
	  replyMessageID: Int? = nil, replyMarkup: MarkupType? = nil) -> TelegramRequest? {
		
		let request = TelegramRequest()
		
		guard FileLink.UploadLocation.stored("") == sticker.location else {
			pelicanPrint("only sending with id UploadLocation is supported."); return nil
		}
		
		request.query = [
			"chat_id": chatID,
			"sticker": sticker.id
		]
		
		// Check whether any other query needs to be added
		if let disableNtf = disableNtf { request.query["disable_notification"] = disableNtf }
		if let replyMessageID = replyMessageID { request.query["reply_to_message_id"] = replyMessageID }
		if let replyMarkup = replyMarkup { request.query["reply_markup"] = replyMarkup.getQuery() }
		
		// Set the query
		request.methodName = "sendSticker"
		
		return request
	}
}
