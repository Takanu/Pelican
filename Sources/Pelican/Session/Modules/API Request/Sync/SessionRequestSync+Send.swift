//
//  SessionRequest+Admin.swift
//  Pelican
//
//  Created by Takanu Kyriako on 16/12/2017.
//

import Foundation

extension SessionRequestSync {
	
	/**
	Sends a text-based message to the chat linked to this session.
	*/
	@discardableResult
	public func sendMessage(_ message: String,
													markup: MarkupType?,
													chatID: Int,
													parseMode: MessageParseMode = .markdown,
													replyID: Int = 0,
													useWebPreview: Bool = false,
													disableNotification: Bool = false) -> Message? {
		
		let request = TelegramRequest.sendMessage(chatID: chatID, text: message, markup: markup, parseMode: parseMode, disableWebPreview: useWebPreview, disableNotification: disableNotification, replyMessageID: replyID)
		let response = tag.sendSyncRequest(request)
		
		if response != nil {
			if response!.success == true {
				
				if let data = response!.result?.rawData() {
					do {
						let decoder = JSONDecoder()
						return try decoder.decode(Message.self, from: response!.data!)
						
					} catch {
						PLog.error("Pelican Response Decode Error (sendMessage:) - \(error) - \(error.localizedDescription)")
					}
				}
			}
		}
		
		return nil
	}
	
	/**
	Sends and uploads a file as a message to the chat linked to this session, using a `FileLink`
	*/
	@discardableResult
	public func sendFile(_ file: MessageFile,
											 caption: String,
											 markup: MarkupType?,
											 chatID: Int,
											 replyID: Int = 0,
											 disableNotification: Bool = false) -> Message? {
		
		let request = TelegramRequest.sendFile(file: file, chatID: chatID, markup: markup, caption: caption, disableNotification: disableNotification, replyMessageID: replyID)
		
		if request == nil {
			return nil
		}
		
		let response = tag.sendSyncRequest(request!)
		
		if response != nil {
			if response!.success == true {
				
				do {
					let decoder = JSONDecoder()
					return try decoder.decode(Message.self, from: response!.data!)
				} catch {
					PLog.error("Pelican Response Decode Error (sendFile:) - \(error) - \(error.localizedDescription)")
				}
			}
		}
		
		return nil
	}
	
	/**
	Use this method when you need to tell the user that something is happening on the bot's side. The status is set for 5 seconds or less (when a message arrives from your bot, Telegram clients clear its typing status).
	- returns: True on success.
	*/
	public func sendChatAction(actionName: String) {
		
	}
}
