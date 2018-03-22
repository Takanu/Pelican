//
//  Request+Send.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 10/07/2017.
//
//

import Foundation

/**
Adds an extension that deals in creating requests for sending chat messages.
*/
extension TelegramRequest {
	
	/** Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Sends a message.  Must contain a chat ID, message text and an optional MarkupType.
	*/
	public static func sendMessage(chatID: Int,
																 text: String,
																 markup: MarkupType?,
																 parseMode: MessageParseMode = .markdown,
																 disableWebPreview: Bool = false,
																 disableNotification: Bool = false,
																 replyMessageID: Int = 0) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id":chatID,
			"text": text,
			"disable_web_page_preview": disableWebPreview,
			"disable_notification": disableNotification
		]
		
		// Check whether any other query needs to be added
		if markup != nil {
			if let text = TelegramRequest.encodeMarkupTypeToUTF8(markup!) {
				request.query["reply_markup"] = text
			}
		}
		
		if parseMode != .none { request.query["parse_mode"] = parseMode.rawValue }
		if replyMessageID != 0 { request.query["reply_to_message_id"] = replyMessageID }
		
		
		// Set the query
		request.method = "sendMessage"
		request.content = text as Any
		
		return request
	}

	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## Function Description
	Uploads a file using any type that follows the MessageFile protocol.
	
	- note: Ensure the MessageFile being sent either has a valid File ID or url to a local or remote resource, or otherwise nothing will be sent
	
	- parameter file: The file to be uploaded.  The MessageFile protocol is adopted by all API types that require the uploading of files, such as `Audio`, `Photo` and `VideoNote`.
	- parameter chatID: The chat you wish to send the file to.
	- parameter caption: Provide an optional caption that will sit below the uploaded file in a Telegram chat.  Note that this only works with Audio,
	Photo, Video, Document and Voice message file types - you wont see a caption appear with any other uploaded file type.
	*/
	public static func sendFile(file: MessageFile,
															chatID: Int,
															markup: MarkupType?,
															caption: String = "",
															disableNotification: Bool = false,
															replyMessageID: Int = 0) -> TelegramRequest? {
		
		let request = TelegramRequest()
		
		request.query["chat_id"] = chatID
		
		// Check whether any other query needs to be added as form data.
		let captionTypes = ["audio", "photo", "video", "document", "voice"]
		
		if caption != "" && captionTypes.contains(file.contentType) {
			request.query["caption"] = caption
		}
		
		if markup != nil {
			if let markupText = TelegramRequest.encodeMarkupTypeToUTF8(markup!) {
				request.query["reply_markup"] = markupText
			}
		}
		
		if replyMessageID != 0 {
			request.query["reply_to_message_id"] = replyMessageID
		}
		
		if disableNotification != false {
			request.query["disable_notification"] = disableNotification
		}
		
		
		// Set the Request, Method and Content
		request.method = file.method
		request.file = file
		
		return request
		
	}
	
	/* Use this method to kick a user from a group or a supergroup. In the case of supergroups, the user will not be able to return to the group on their own using invite links, etc., unless unbanned first. The bot must be an administrator in the group for this to work. Returns True on success. */
	public static func sendChatAction(chatID: Int, action: ChatAction) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": chatID,
			"action": action.rawValue
		]
		
		// Set the Request, Method and Content
		request.method = "sendChatAction"
		request.content = action as Any
		
		return request
	}
	
	/* Use this method to send a game. On success, the sent Message is returned. */
	public static func sendGame(chatID: Int, gameName: String, markup: MarkupType?, disableNotification: Bool = false, replyMessageID: Int = 0) -> TelegramRequest {
		
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
	public static func setGameScore(userID: Int, score: Int, force: Bool = false, disableEdit: Bool = false, chatID: Int = 0, messageID: Int = 0, inlineMessageID: Int = 0) -> TelegramRequest {
		
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
	public static func getGameHighScores(userID: Int, chatID: Int = 0, messageID: Int = 0, inlineMessageID: Int = 0) -> TelegramRequest {
		
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
