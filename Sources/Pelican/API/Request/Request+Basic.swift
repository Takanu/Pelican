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
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## Function Description
	A simple method for getting updates for your bot.  This is not needed unless you're interested in generally bypassing all the Pelican goodness.
	*/
	public static func getUpdates(incrementUpdate: Bool = true) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.method = "getUpdates"
		return request
	}
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	A simple method for testing your bot's auth token. Requires no parameters. Returns basic information about the bot in form of a User object.
	*/
	public static func getMe() -> TelegramRequest {
		
		let request = TelegramRequest()
		request.method = "getMe"
		
		return request
	}
	
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
	
	// Forwards a message of any kind.  On success, the sent Message is returned.
	static public func forwardMessage(toChatID: Int,
																		fromChatID: Int,
																		fromMessageID: Int,
																		disableNotification: Bool = false) -> TelegramRequest {
		
		let request = TelegramRequest()
		request.method = "forwardMessage"
		
		request.query = [
			"chat_id": toChatID,
			"from_chat_id": fromChatID,
			"message_id": fromMessageID,
			"disable_notification": disableNotification
		]
		
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
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to get a list of profile pictures for a user. Returns a UserProfilePhotos object.
	*/
	public static func getUserProfilePhotos(userID: Int, offset: Int = 0, limit: Int = 100) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		// I know this could be neater, figure something else later
		let adjustedLimit = max(0, min(100, limit))
		
		request.query = [
			"user_id": userID,
			"offset": offset,
			"limit": adjustedLimit
		]
		
		// Set the Request, Method and Content
		request.method = "getUserProfilePhotos"
		
		return request
	}
	
	
	/* Use this method to kick a user from a group or a supergroup. In the case of supergroups, the user will not be able to return to the group on their own using invite links, etc., unless unbanned first. The bot must be an administrator in the group for this to work. Returns True on success. */
	public static func sendChatAction(action: ChatAction, chatID: Int) -> TelegramRequest {
		
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
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to get basic info about a file and prepare it for downloading. For the moment, bots can download files of up to 20MB in size. On success, a File object is returned. The file can then be downloaded via the link
	https://api.telegram.org/file/bot<token>/<file_path>, where <file_path> is taken from the response. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling
	getFile again.
	*/
	public static func getFile(fileID: String) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"file_id": fileID
		]
		
		// Set the Request, Method and Content
		request.method = "getFile"
		request.content = fileID as Any
		
		return request
		
	}
}
