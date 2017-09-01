//
//  Send.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation
import Vapor
import Fluent

/**
A delegate for a session, to send requests to Telegram that correspond with sending chat messages.

One of a collection of delegates used to let Sessions make requests to Telegram in a language and format
thats concise, descriptive and direct.
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
	public func message(_ message: String, markup: MarkupType?, parseMode: MessageParseMode = .markdown, replyID: Int = 0, webPreview: Bool = false, disableNtf: Bool = false) -> Message {
		
		let request = TelegramRequest.sendMessage(chatID: chatID, text: message, replyMarkup: markup, parseMode: parseMode, disableWebPreview: webPreview, disableNtf: disableNtf, replyMessageID: replyID)
		let response = tag.sendRequest(request)
		
		return try! Message(row: Row(response.data!))
	}
	
	/**
	Sends and uploads a file as a message to the chat linked to this session, using a `FileLink`
	*/
	public func file(_ file: MessageFile, caption: String, markup: MarkupType?, replyID: Int = 0, disableNtf: Bool = false, callback: ReceiveUpload? = nil) {
		
		let request = TelegramRequest.sendFile(file: file, callback: nil, chatID: chatID, markup: markup, caption: caption, disableNtf: disableNtf, replyMessageID: replyID)
		_ = tag.sendRequest(request)
	}
}
