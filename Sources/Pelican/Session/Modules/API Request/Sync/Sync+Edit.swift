//
//  MethodRequest+Edit.swift
//  Pelican
//
//  Created by Takanu Kyriako on 16/12/2017.
//

import Foundation

extension MethodRequestSync {
	
	/**
	Edits a text based message.
	*/
	@discardableResult
	public func editMessage(_ message: String,
													messageID: Int?,
													inlineMessageID: Int?,
													markup: MarkupType? = nil,
													chatID: String,
													parseMode: MessageParseMode = .markdown,
													disableWebPreview: Bool = false) -> Bool {
		
		let request = TelegramRequest.editMessageText(chatID: chatID,
																									messageID: messageID,
																									inlineMessageID: inlineMessageID,
																									text: message,
																									markup: markup,
																									parseMode: parseMode,
																									disableWebPreview: disableWebPreview)
		
		let response = tag.sendSyncRequest(request)
		if response == nil { return false }
		
		if response!.result?["chat"] != nil { return true }
		else { return MethodRequest.decodeResponse(response) ?? false }
	}
	
	/**
	Edits the caption on a media/file based message.
	*/
	@discardableResult
	public func editCaption(messageID: Int = 0,
													caption: String,
													markup: MarkupType? = nil,
													chatID: String) -> Bool {
		
		let request = TelegramRequest.editMessageCaption(chatID: chatID,
																										 messageID: messageID,
																										 caption: caption,
																										 markup: markup)
		let response = tag.sendSyncRequest(request)
		if response == nil { return false }
		
		if response!.result?["chat"] != nil { return true }
		else { return MethodRequest.decodeResponse(response) ?? false }
	}
	
	/**
	Edits the inline markup options assigned to any type of message.
	*/
	@discardableResult
	public func editReplyMarkup(_ markup: MarkupType,
															messageID: Int = 0,
															inlineMessageID: Int = 0,
															chatID: String) -> Bool {
		
		let request = TelegramRequest.editMessageReplyMarkup(chatID: chatID, messageID: messageID, inlineMessageID: inlineMessageID, markup: markup)
		let response = tag.sendSyncRequest(request)
		if response == nil { return false }
		
		if response!.result?["chat"] != nil { return true }
		else { return MethodRequest.decodeResponse(response) ?? false }
	}
	
	/**
	Deletes a message the bot has made using it's message ID.  This method has the following limitations:
	- A message can only be deleted if it was sent less than 48 hours ago.
	- Bots can delete outgoing messages in groups and supergroups.
	- Bots granted can_post_messages permissions can delete outgoing messages in channels.
	- If the bot is an administrator of a group, it can delete any message there.
	- If the bot has can_delete_messages permission in a supergroup or a channel, it can delete any message there.
	*/
	@discardableResult
	public func deleteMessage(_ messageID: Int, chatID: String) -> Bool {
		
		let request = TelegramRequest.deleteMessage(chatID: chatID, messageID: messageID)
		let response = tag.sendSyncRequest(request)
		return MethodRequest.decodeResponse(response) ?? false
	}
	
}

