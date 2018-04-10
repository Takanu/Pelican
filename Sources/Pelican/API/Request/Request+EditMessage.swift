//
//  Request+Edit.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 10/07/2017.
//
//

import Foundation

/**
Adds an extension that deals in creating requests for editing messages in a chat.
*/
extension TelegramRequest {
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to edit text and game messages sent by the bot or via the bot (for inline bots). On success, if edited message is sent by the bot, the edited Message is returned, otherwise True is returned.
	*/
	public static func editMessageText(chatID: String?,
																		 messageID: Int?,
																		 inlineMessageID: Int?,
																		 text: String,
																		 markup: MarkupType?,
																		 parseMode: MessageParseMode = .markdown,
																		 disableWebPreview: Bool = false) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		if chatID != nil { request.query["chat_id"] = chatID }
		if messageID != nil { request.query["message_id"] = messageID }
		if inlineMessageID != nil { request.query["inline_message_id"] = inlineMessageID }
		
		// Check whether any other query needs to be added
		request.query["text"] = text
		
		if markup != nil {
			if let text = TelegramRequest.encodeMarkupTypeToUTF8(markup!) {
				request.query["reply_markup"] = text
			}
		}
		
		if parseMode != .none { request.query["parse_mode"] = parseMode.rawValue }
		
		// Set the query
		request.method = "editMessageText"
		request.content = text as Any
		
		return request
		
	}
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to edit captions of messages sent by the bot or via the bot (for inline bots). On success, 
	if edited message is sent by the bot, the edited Message is returned, otherwise True is returned.
	*/
	public static func editMessageCaption(chatID: String, messageID: Int = 0, caption: String, markup: MarkupType?) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id":chatID,
			"caption": caption,
		]
		
		// Check whether any other query needs to be added
		if messageID != 0 { request.query["message_id"] = messageID }
		
		if markup != nil {
			if let text = TelegramRequest.encodeMarkupTypeToUTF8(markup!) {
				request.query["reply_markup"] = text
			}
		}
		
		// Set the query
		request.method = "editMessageCaption"
		request.content = caption as Any
		
		return request
		
	}
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to edit only the reply markup of messages sent by the bot or via the bot (for inline bots). On success, 
	if edited message is sent by the bot, the edited Message is returned, otherwise True is returned.
	*/
	public static func editMessageReplyMarkup(chatID: String, messageID: Int = 0, inlineMessageID: Int = 0, markup: MarkupType?) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id":chatID,
		]
		
		// Check whether any other query needs to be added
		if messageID != 0 { request.query["message_id"] = messageID }
		if inlineMessageID != 0 { request.query["inline_message_id"] = inlineMessageID }
		
		if markup != nil {
			if let text = TelegramRequest.encodeMarkupTypeToUTF8(markup!) {
				request.query["reply_markup"] = text
			}
		}
		
		// Set the query
		request.method = "editMessageReplyMarkup"
		request.content = markup as Any
		
		return request
		
	}
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to delete a message, including service messages, with the following limitations:
	- A message can only be deleted if it was sent less than 48 hours ago.
	- Bots can delete outgoing messages in groups and supergroups.
	- Bots granted can_post_messages permissions can delete outgoing messages in channels.
	- If the bot is an administrator of a group, it can delete any message there.
	- If the bot has can_delete_messages permission in a supergroup or a channel, it can delete any message there.
	Returns True on success.
	*/
	public static func deleteMessage(chatID: String, messageID: Int) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": chatID,
			"message_id": messageID
		]

		
		// Set the query
		request.method = "deleteMessage"
		return request
	}
	
	
}
