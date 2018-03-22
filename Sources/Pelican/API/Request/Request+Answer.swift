//
//  Request+Answer.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 12/07/2017.
//
//

import Foundation

/**
Adds an extension that deals in answering queries sent by a user in various contexts.
*/
extension TelegramRequest {
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to send answers to callback queries sent from inline keyboards. The answer will be displayed to the user as a notification at the top of the chat screen or as an alert. On success, True is returned.
	
	Alternatively, the user can be redirected to the specified Game URL. For this option to work, you must first create a game for your bot via BotFather and accept the terms. Otherwise, you may use links like t.me/your_bot start=XXXX that open your bot with a parameter.
	*/
	public static func answerCallbackQuery(queryID: String, text: String?, showAlert: Bool, url: String?, cacheTime: Int = 0) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"callback_query_id": queryID
		]
		
		if text != nil { request.query["text"] = text! }
		if showAlert == true { request.query["show_alert"] = showAlert }
		if url != nil { request.query["url"] = url! }
		if cacheTime != 0 { request.query["cache_time"] = cacheTime }
		
		
		// Set the query
		request.method = "answerCallbackQuery"
		request.content = text as Any
		
		return request
	}
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to send answers to callback queries sent from inline keyboards. The answer will be displayed to the user as a notification at the top of the chat screen or as an alert. On success, True is returned.
	
	Use this method to send answers to an inline query. On success, True is returned.
	No more than 50 results per query are allowed.
	*/
	public static func answerInlineQuery(queryID: String, results: [InlineResult], cacheTime: Int = 0, isPersonal: Bool = false, nextOffset: String?, switchPM: String?, switchPMParam: String?) -> TelegramRequest? {
		
		let request = TelegramRequest()
		
		request.query = [
			"inline_query_id": queryID
		]
		
		let resultAny: [InlineResultAny] = results.map {T in return InlineResultAny(T) }
		request.query["results"] = TelegramRequest.encodeDataToUTF8(resultAny)
		
		// Check whether any other query needs to be added
		if cacheTime != 300 { request.query["cache_time"] = cacheTime }
		if isPersonal != false { request.query["is_personal"] = isPersonal }
		if nextOffset != nil { request.query["next_offset"] = nextOffset }
		if switchPM != "" { request.query["switch_pm_text"] = switchPM }
		if switchPMParam != "" { request.query["switch_pm_parameter"] = switchPMParam }
		
		
		// Set the query
		request.method = "answerInlineQuery"
		request.content = results as Any
		
		return request
	}
}
	
