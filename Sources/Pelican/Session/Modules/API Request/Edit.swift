//
//  Edit.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation
import Vapor

/**
A delegate for a session, to send requests to Telegram that correspond with editing chat messages sent by the bot.

One of a collection of delegates used to let Sessions make requests to Telegram in a language and format
thats concise, descriptive and direct.
*/
public class TGEdit {
	
	var chatID: Int
	var tag: SessionTag
	
	init(chatID: Int, tag: SessionTag) {
		self.chatID = chatID
		self.tag = tag
	}
	
	/**
	Edits a text based message.
	*/
	public func message(messageID: Int?, inlineMessageID: Int?, text: String, replyMarkup: MarkupType?, parseMode: MessageParseMode = .markdown, disableWebPreview: Bool = false) {
		
		let request = TelegramRequest.editMessageText(chatID: chatID, messageID: messageID, inlineMessageID: inlineMessageID, text: text, replyMarkup: replyMarkup, parseMode: parseMode, disableWebPreview: disableWebPreview)
		_ = tag.sendRequest(request)
	}
	
	/**
	Edits the caption on a media/file based message.
	*/
	public func caption(messageID: Int = 0, caption: String, replyMarkup: MarkupType?) {
		
		let request = TelegramRequest.editMessageCaption(chatID: chatID, messageID: messageID, caption: caption, replyMarkup: replyMarkup)
		_ = tag.sendRequest(request)
	}
	
	/**
	Edits the inline markup options assigned to any type of message/
	*/
	public func replyMarkup(messageID: Int = 0, inlineMessageID: Int = 0, replyMarkup: MarkupType?) {
		
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
	public func delete(messageID: Int) {
		
		let request = TelegramRequest.deleteMessage(chatID: chatID, messageID: messageID)
		_ = tag.sendRequest(request)
	}
}
