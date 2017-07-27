//
//  APIRequest.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 12/07/2017.
//
//

import Foundation
import Vapor

/**
A delegate for a session, to send requests to Telegram that correspond with sending chat messages.
*/
public class TGSend {
	
	var chatID: Int
	var tag: SessionTag
	
	init(chatID: Int, tag: SessionTag) {
		self.chatID = chatID
		self.tag = tag
	}
	
	/**
	Sends a text-based message to the chat linked to this session.
	*/
	public func message(_ message: String, markup: MarkupType?, parseMode: MessageParseMode = .markdown, replyID: Int = 0, webPreview: Bool = false, disableNtf: Bool = false) {
		
		let request = TelegramRequest.sendMessage(chatID: chatID, text: message, replyMarkup: markup, parseMode: parseMode, disableWebPreview: webPreview, disableNtf: disableNtf, replyMessageID: replyID)
		_ = tag.sendRequest(request)
	}
	
	/**
	Sends and uploads a file as a message to the chat linked to this session, using a `FileLink`
	*/
	public func file(_ link: FileLink, caption: String, markup: MarkupType?, replyID: Int = 0, disableNtf: Bool = false, callback: ReceiveUpload? = nil) {
		
		let request = TelegramRequest.uploadFile(link: link, callback: callback, chatID: chatID, markup: markup, caption: caption, disableNtf: disableNtf, replyMessageID: replyID)
		_ = tag.sendRequest(request)
	}
}


/**
A delegate for a session, to send requests to Telegram that correspond with editing chat messages sent by the bot.
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
	public func message(messageID: Int?, inlineMessageID: Int?, text: String, replyMarkup: MarkupType?, parseMode: MessageParseMode = .none, disableWebPreview: Bool = false) {
		
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


/**
A delegate for a session, to send requests to Telegram that correspond with administrating a group
*/
public class TGAdmin {
	
	var chatID: Int
	var tag: SessionTag
	
	init(chatID: Int, tag: SessionTag) {
		self.chatID = chatID
		self.tag = tag
	}
	
	/**
	Kicks a user from the chat.
	*/
	public func kick(_ userID: Int) {
		
		let request = TelegramRequest.kickChatMember(chatID: chatID, userID: userID)
		_ = tag.sendRequest(request)
	}
	
	/**
	Unbans a user from the chat.
	*/
	public func unban(_ userID: Int) {
		
		let request = TelegramRequest.unbanChatMember(chatID: chatID, userID: userID)
		_ = tag.sendRequest(request)
	}
	
	/**
	Applies chat restrictions to a user.
	*/
	public func restrict(_ userID: Int, restrictUntil: Int?, restrictions: (msg: Bool, media: Bool, stickers: Bool, webPreview: Bool)?) {
		
		let request = TelegramRequest.restrictChatMember(chatID: chatID, userID: userID, restrictUntil: restrictUntil, restrictions: restrictions)
		_ = tag.sendRequest(request)
	}
	
	/**
	Promotes a user to an admin, while being able to define the privileges they have.
	*/
	public func promote(_ userID: Int, rights: (info: Bool, msg: Bool, edit: Bool, delete: Bool, invite: Bool, restrict: Bool, pin: Bool, promote: Bool)?) {
		
		let request = TelegramRequest.promoteChatMember(chatID: chatID, userID: userID, rights: rights)
		_ = tag.sendRequest(request)
	}
	
	/**
	Returns an already existing invite link, or generates one if none currently exist.
	*/
	public func getInviteLink() {
		
		let request = TelegramRequest.exportChatInviteLink(chatID: chatID)
		_ = tag.sendRequest(request)
	}
	
	/**
	Sets the profile photo for the chat, using a `FileLink`.
	*/
	public func setChatPhoto(file: FileLink) {
		
		let request = TelegramRequest.setChatPhoto(chatID: chatID, file: file)
		_ = tag.sendRequest(request)
	}
	
	/**
	Deletes the currently set chat photo.
	*/
	public func deleteChatPhoto() {
		
		let request = TelegramRequest.deleteChatPhoto(chatID: chatID)
		_ = tag.sendRequest(request)
	}
	
	/**
	Sets the chat name/title.
	*/
	public func setChatTitle(_ title: String) {
		
		let request = TelegramRequest.setChatTitle(chatID: chatID, title: title)
		_ = tag.sendRequest(request)
	}
	
	/**
	Sets the chat description.
	*/
	public func setChatDescription(_ description: String) {
		
		let request = TelegramRequest.setChatDescription(chatID: chatID, description: description)
		_ = tag.sendRequest(request)
	}
	
	/**
	Pins a message using the given message ID.
	*/
	public func pin(messageID: Int, disableNtf: Bool = false) {
		
		let request = TelegramRequest.pinChatMessage(chatID: chatID, messageID: messageID, disableNtf: disableNtf)
		_ = tag.sendRequest(request)
	}
	
	/**
	Unpins the currently pinned message.
	*/
	public func unpin() {
		
		let request = TelegramRequest.unpinChatMessage(chatID: chatID)
		_ = tag.sendRequest(request)
	}
	
}


/**
A delegate for a session, to send requests to Telegram that correspond with sending chat messages.
*/
public class TGAnswer {
	
	var tag: SessionTag
	
	init(tag: SessionTag) {
		self.tag = tag
	}
	
	/**
	Sends a text-based message to the chat linked to this session.
	*/
	public func callbackQuery(queryID: String, text: String?, showAlert: Bool, url: String = "", cacheTime: Int = 0) {
		
		let request = TelegramRequest.answerCallbackQuery(queryID: queryID, text: text, showAlert: showAlert, url: url, cacheTime: cacheTime)
		_ = tag.sendRequest(request)
	}
	
	/**
	Sends and uploads a file as a message to the chat linked to this session, using a `FileLink`
	*/
	public func inlineQuery(queryID: Int, results: [InlineResult], cacheTime: Int = 0, isPersonal: Bool = false, nextOffset: String?, switchPM: String?, switchPMParam: String?) {
		
		let request = TelegramRequest.answerInlineQuery(queryID: queryID, results: results, cacheTime: cacheTime, isPersonal: isPersonal, nextOffset: nextOffset, switchPM: switchPM, switchPMParam: switchPMParam)
		_ = tag.sendRequest(request)
	}
}
