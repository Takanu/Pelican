//
//  Request+Game.swift
//  Pelican
//
//  Created by Ido Constantine on 22/03/2018.
//

import Foundation

/**
Adds an extension that deals in performing game-related activities.
*/
extension TelegramRequest {
	
	/* Use this method to send a game. On success, the sent Message is returned. */
	public static func sendGame(chatID: String, gameName: String, markup: MarkupType?, disableNotification: Bool = false, replyMessageID: Int = 0) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id":chatID,
			"game_short_name": gameName
		]
		
		// Check whether any other query needs to be added
		if markup != nil {
			if let markupText = TelegramRequest.encodeMarkupTypeToUTF8(markup!) {
				request.query["reply_markup"] = markupText
			}
		}
		
		if replyMessageID != 0 { request.query["reply_to_message_id"] = replyMessageID }
		if disableNotification != false { request.query["disable_notification"] = disableNotification }
		
		// Set the query
		request.method = "sendGame"
		request.content = gameName as Any
		
		return request
	}
	
	/* Use this method to set the score of the specified user in a game. On success, if the message was sent by the bot, returns the edited Message, otherwise returns True. Returns an error, if the new score is not greater than the user's current score in the chat and force is False. */
	public static func setGameScore(userID: String,
																	score: Int,
																	force: Bool = false,
																	disableEdit: Bool = false,
																	chatID: String = "0",
																	messageID: Int = 0,
																	inlineMessageID: Int = 0) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"user_id":userID,
			"score": score
		]
		
		// Check whether any other query needs to be added
		if force != false { request.query["force"] = force }
		if disableEdit != false { request.query["disable_edit_message"] = disableEdit }
		
		// THIS NEEDS EDITING PROBABLY, NOT NICE DESIGN
		if inlineMessageID == 0 {
			request.query["chat_id"] = chatID
			request.query["message_id"] = messageID
		}
			
		else {
			request.query["inline_message_id"] = inlineMessageID
		}
		
		// Set the query
		request.method = "setGameScore"
		request.content = score as Any
		
		return request
		
	}
	
	/* Use this method to get data for high score tables. Will return the score of the specified user and several of his neighbors in a game. On success, returns an Array of GameHighScore objects.
	
	This method will currently return scores for the target user, plus two of his closest neighbors on each side. Will also return the top three users if the user and his neighbors are not among them. Please note that this behavior is subject to change. */
	public static func getGameHighScores(userID: String, chatID: String = "0", messageID: Int = 0, inlineMessageID: Int = 0) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"user_id":userID
		]
		
		// THIS NEEDS EDITING PROBABLY, NOT NICE DESIGN
		if inlineMessageID == 0 {
			request.query["chat_id"] = chatID
			request.query["message_id"] = messageID
		}
			
		else {
			request.query["inline_message_id"] = inlineMessageID
		}
		
		// Set the query
		request.method = "getGameHighScores"
		
		return request
		
	}
	

}
