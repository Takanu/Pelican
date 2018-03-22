//
//  SessionRequest+Admin.swift
//  Pelican
//
//  Created by Takanu Kyriako on 16/12/2017.
//

import Foundation

extension SessionRequestSync {
	
	/**
	A basic function for testing authorisation tokens, that returns your bot as a user if successful.
	*/
	func getMe() -> User? {
		
		let request = TelegramRequest.getMe()
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response)
	}
	
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
		
		let request = TelegramRequest.sendMessage(chatID: chatID,
																							text: message,
																							markup: markup,
																							parseMode: parseMode,
																							disableWebPreview: useWebPreview,
																							disableNotification: disableNotification,
																							replyMessageID: replyID)
		
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response!)
	}
	
	/**
	Forward a message of any kind.
	*/
	@discardableResult
	public func forwardMessage(toChatID: Int, fromChatID: Int, fromMessageID: Int, disableNotification: Bool = false) -> Message? {
		
		let request = TelegramRequest.forwardMessage(toChatID: toChatID, fromChatID: fromChatID, fromMessageID: fromMessageID, disableNotification: disableNotification)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response!)
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
		
		if request == nil { return nil }
		
		let response = tag.sendSyncRequest(request!)
		return SessionRequest.decodeResponse(response)
	}
	
	
	/**
	Use this method when you need to tell the user that something is happening on the bot's side. The status is set for 5 seconds or less (when a message arrives from your bot, Telegram clients clear its typing status).
	- returns: True on success.
	*/
	public func sendChatAction(_ actionType: ChatAction, chatID: Int) -> Bool {
		
		let request = TelegramRequest.sendChatAction(action: actionType, chatID: chatID)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response) ?? false
	}
	
	
	/**
	Returns a list of profile pictures for the specified user.
	*/
	public func getUserProfilePhotos(userID: Int, offset: Int = 0, limit: Int = 100) -> UserProfilePhotos? {
		
		let request = TelegramRequest.getUserProfilePhotos(userID: userID, offset: offset, limit: limit)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response)
	}
	
	/**
	Use this method to get basic info about a file and prepare it for downloading. For the moment, bots can download files of up to 20MB in size. On success, a File object is returned. The file can then be downloaded via the link
	https://api.telegram.org/file/bot<token>/<file_path>, where <file_path> is taken from the response. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling
	getFile again.
	*/
	public func getFile(fileID: String) -> FileDownload? {
		
		let request = TelegramRequest.getFile(fileID: fileID)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response)
	}
}
