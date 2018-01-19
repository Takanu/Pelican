//
//  Request+Send.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 10/07/2017.
//
//

import Foundation
import Vapor
import FluentProvider
import HTTP
import FormData
import Multipart

/**
Adds an extension that deals in creating requests for sending chat messages.
*/
extension TelegramRequest {
	
	/** Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Sends a message.  Must contain a chat ID, message text and an optional MarkupType.
	*/
	public static func sendMessage(chatID: Int, text: String, markup: MarkupType?, parseMode: MessageParseMode = .markdown, disableWebPreview: Bool = false, disableNotification: Bool = false, replyMessageID: Int = 0) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id":chatID,
			"text": text,
			"disable_web_page_preview": disableWebPreview,
			"disable_notification": disableNotification
		]
		
		// Check whether any other query needs to be added
		if markup != nil {
			if let text = TelegramRequest.encodeDataToUTF8(markup!) {
				request.query["reply_markup"] = text
			}
		}
		
		if parseMode != .none { request.query["parse_mode"] = parseMode.rawValue }
		if replyMessageID != 0 { request.query["reply_to_message_id"] = replyMessageID }
		
		
		// Set the query
		request.methodName = "sendMessage"
		request.content = text as Any
		
		return request
	}
	
	/*
	/** Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## Builder Description
	Sends a file based on the given "SendType", which defines both the ID of the file and 
	*/
	public func sendFile(chatID: Int, file: SendType, markup: MarkupType?, caption: String = "", disableNotification: Bool = false, replyMessageID: Int = 0) {
		
		query = [
			"chat_id":chatID
		]
		
		// Ensure only the files that can have caption types get a caption query
		let captionTypes = ["audio", "photo", "video", "document", "voice"]
		if caption != "" && captionTypes.index(of: file.messageTypeName) != nil { query["caption"] = caption }
		
		// Check whether any other query needs to be added
		if markup != nil { query["reply_markup"] = markup!.getQuery() }
		if replyMessageID != 0 { query["reply_to_message_id"] = replyMessageID }
		if disableNotification != false { query["disable_notification"] = disableNotification }
		
		// Combine the query built above with the one the file provides
		let finalQuery = query.reduce(file.getQuery(), { r, e in var r = r; r[e.0] = e.1; return r })
		
		// Set the Request, Method and Content
		methodName = file.method
		content = file as Any
		
	}
	*/
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## Function Description
	Uploads a file using any type that follows the MessageFile protocol.
	
	- note: Ensure the MessageFile being sent either has a valid File ID or url to a local or remote resource, or otherwise nothing will be sent
	
	- parameter file: The file to be uploaded.  The MessageFile protocol is adopted by all API types that require the uploading of files, such as `Audio`, `Photo` and `VideoNote`.
	- parameter callback: TBA
	- parameter chatID: The chat you wish to send the file to
	- parameter caption: Provide an optional caption that will sit below the uploaded file in a Telegram chat.  Note that this only works with Audio,
	Photo, Video, Document and Voice message file types - you wont see a caption appear with any other uploaded file type.
	*/
	public static func sendFile(file: MessageFile, callback: ReceiveUpload? = nil, chatID: Int, markup: MarkupType?, caption: String = "", disableNotification: Bool = false, replyMessageID: Int = 0) -> TelegramRequest? {
		
		
		// The PhotoSize/Photo model stopped working, this can't be used until later.
		/*
		// Check to see if we need to upload this in the first place.
		// If not, send the file using the link.
		let search = cache.find(upload: link, bot: self)
		if search != nil {
		print("SENDING...")
		let message = sendFile(chatID: chatID, file: search!, markup: markup, caption: caption, disableNotification: disableNotification, replyMessageID: replyMessageID)
		if callback != nil {
		callback!.receiveMessage(message: message!)
		}
		return
		}
		*/
		
		let request = TelegramRequest()
		
		// If have a File ID, add it here.
		if file.fileID != nil {
			request.query["chat_id"] = chatID
			request.query[file.contentType] = file.fileID!
			
			// Check whether any other query needs to be added as form data.
			let captionTypes = ["audio", "photo", "video", "document", "voice"]
			
			if caption != "" && captionTypes.contains(file.contentType) {
				request.query["caption"] = caption
			}
			
			if markup != nil {
				if let markupText = TelegramRequest.encodeDataToUTF8(markup!) {
					request.query["reply_markup"] = markupText
				}
			}
			
			if replyMessageID != 0 {
				request.query["reply_to_message_id"] = replyMessageID
			}
			
			if disableNotification != false {
				request.query["disable_notification"] = disableNotification
			}
		}
		
		else {
			// Create the form data and assign some initial values
			request.form["chat_id"] = Field(name: "chat_id", filename: nil, part: Part(headers: [:], body: String(chatID).bytes))
			
			// Check whether any other query needs to be added as form data.
			let captionTypes = ["audio", "photo", "video", "document", "voice"]
			
			if caption != "" && captionTypes.contains(file.contentType) {
				request.form["caption"] = Field(name: "caption", filename: nil, part: Part(headers: [:], body: caption.bytes))
			}
			
			if markup != nil {
				if let text = TelegramRequest.encodeDataToUTF8(markup!) {
					request.form["reply_markup"] = Field(name: "reply_markup", filename: nil, part: Part(headers: [:], body: text.makeBytes()))
				}
			}
			
			if replyMessageID != 0 {
				request.form["reply_to_message_id"] = Field(name: "reply_to_message_id", filename: nil, part: Part(headers: [:], body: String(replyMessageID).bytes))
			}
			
			if disableNotification != false {
				request.form["disable_notification"] = Field(name: "disable_notification", filename: nil, part: Part(headers: [:], body: String(disableNotification).bytes))
			}
		}
		
		
		
		// Set the Request, Method and Content
		request.methodName = file.method
		request.content = file as Any // We'll deal with this at the point Pelican receives the request.
		
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
		request.methodName = "sendChatAction"
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
			if let markupText = TelegramRequest.encodeDataToUTF8(markup!) {
				request.query["reply_markup"] = markupText
			}
		}
		
		if replyMessageID != 0 { request.query["reply_to_message_id"] = replyMessageID }
		if disableNotification != false { request.query["disable_notification"] = disableNotification }
		
		// Set the query
		request.methodName = "sendGame"
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
		request.methodName = "setGameScore"
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
		request.methodName = "getGameHighScores"
		
		return request
		
	}
	
}
