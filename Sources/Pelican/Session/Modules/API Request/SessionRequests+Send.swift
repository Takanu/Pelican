//
//  SessionRequests+Admin.swift
//  Pelican
//
//  Created by Ido Constantine on 16/12/2017.
//

import Foundation
import Vapor
import Fluent

extension SessionRequests {
	
	/**
	Sends a text-based message to the chat linked to this session.
	*/
	@discardableResult
	public func sendMessage(_ message: String, markup: MarkupType?, chatID: Int, parseMode: MessageParseMode = .markdown, replyID: Int = 0, useWebPreview: Bool = false, disableNotification: Bool = false) -> Message {
		
		let request = TelegramRequest.sendMessage(chatID: chatID, text: message, replyMarkup: markup, parseMode: parseMode, disableWebPreview: useWebPreview, disableNotification: disableNotification, replyMessageID: replyID)
		let response = tag.sendRequest(request)
		
		return try! Message(row: Row(response.data!))
	}
	
	/**
	Sends and uploads a file as a message to the chat linked to this session, using a `FileLink`
	*/
	@discardableResult
	public func sendFile(_ file: MessageFile, caption: String, markup: MarkupType?, chatID: Int, replyID: Int = 0, disableNotification: Bool = false) -> Message {
		
		let request = TelegramRequest.sendFile(file: file, callback: nil, chatID: chatID, markup: markup, caption: caption, disableNotification: disableNotification, replyMessageID: replyID)
		let response = tag.sendRequest(request)
		
		return try! Message(row: Row(response.data!))
	}
	
	/**
	Use this method when you need to tell the user that something is happening on the bot's side. The status is set for 5 seconds or less (when a message arrives from your bot, Telegram clients clear its typing status).
	- returns: True on success.
	*/
	public func sendChatAction(actionName: String) {
		
	}
}
