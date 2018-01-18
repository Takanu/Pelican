//
//  SessionRequests+Edit.swift
//  Pelican
//
//  Created by Ido Constantine on 16/12/2017.
//

import Foundation

extension SessionRequests {
	
	/**
	Edits a text based message.
	*/
	public func editMessage(_ message: String, messageID: Int?, inlineMessageID: Int?, replyMarkup: MarkupType?, chatID: Int, parseMode: MessageParseMode = .markdown, disableWebPreview: Bool = false) {
		
		let request = TelegramRequest.editMessageText(chatID: chatID, messageID: messageID, inlineMessageID: inlineMessageID, text: message, replyMarkup: replyMarkup, parseMode: parseMode, disableWebPreview: disableWebPreview)
		_ = tag.sendRequest(request)
	}
	
	/**
	Edits the caption on a media/file based message.
	*/
	public func editCaption(messageID: Int = 0, caption: String, replyMarkup: MarkupType?, chatID: Int) {
		
		let request = TelegramRequest.editMessageCaption(chatID: chatID, messageID: messageID, caption: caption, replyMarkup: replyMarkup)
		_ = tag.sendRequest(request)
	}
	
	/**
	Edits the inline markup options assigned to any type of message/
	*/
	public func editReplyMarkup(_ replyMarkup: MarkupType?, messageID: Int = 0, inlineMessageID: Int = 0, chatID: Int) {
		
		let request = TelegramRequest.editMessageReplyMarkup(chatID: chatID, messageID: messageID, inlineMessageID: inlineMessageID, replyMarkup: replyMarkup)
		_ = tag.sendRequest(request)
	}
	
	/**
	Deletes a message the bot has made using it's message ID.  This method has the following limitations:
	- A message can only be deleted if it was sent less than 48 hours ago.
	- Bots can delete outgoing messages in groups and supergroups.
	- Bots granted can_post_messages permissions can delete outgoing messages in channels.
	- If the bot is an administrator of a group, it can delete any message there.
	- If the bot has can_delete_messages permission in a supergroup or a channel, it can delete any message there.
	*/
	public func deleteMessage(_ messageID: Int, chatID: Int) {
		
		let request = TelegramRequest.deleteMessage(chatID: chatID, messageID: messageID)
		_ = tag.sendRequest(request)
	}
	
}
