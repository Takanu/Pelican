//
//  SessionRequest+Ad,om.swift
//  Pelican
//
//  Created by Takanu Kyriako on 16/12/2017.
//

import Foundation

/**
This extension handles any kinds of operations involving group moderation and how the group details are presented and changed.
*/
extension SessionRequestSync {
	
	/**
	Kicks a user from the chat.
	*/
	@discardableResult
	public func kickUser(_ userID: Int, chatID: Int) -> Bool {
		
		let request = TelegramRequest.kickChatMember(chatID: chatID, userID: userID)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response) ?? false
	}
	
	/**
	Unbans a user from the chat.
	*/
	@discardableResult
	public func unbanUser(_ userID: Int, chatID: Int) -> Bool {
		
		let request = TelegramRequest.unbanChatMember(chatID: chatID, userID: userID)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response) ?? false
	}
	
	/**
	Applies chat restrictions to a user.
	*/
	@discardableResult
	public func restrictUser(_ userID: Int,
													 chatID: Int,
													 restrictUntil: Int?,
													 restrictions: (msg: Bool, media: Bool, stickers: Bool, useWebPreview: Bool)?) -> Bool {
		
		let request = TelegramRequest.restrictChatMember(chatID: chatID, userID: userID, restrictUntil: restrictUntil, restrictions: restrictions)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response) ?? false
	}
	
	/**
	Promotes a user to an admin, while being able to define the privileges they have.
	*/
	@discardableResult
	public func promoteUser(_ userID: Int,
													chatID: Int,
													rights: (info: Bool, msg: Bool, edit: Bool, delete: Bool, invite: Bool, restrict: Bool, pin: Bool, promote: Bool)?) -> Bool {
		
		let request = TelegramRequest.promoteChatMember(chatID: chatID, userID: userID, rights: rights)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response) ?? false
	}
	
	/**
	Returns an already existing invite link, or generates one if none currently exist.
	*/
	public func getInviteLink(chatID: Int) -> String? {
		
		let request = TelegramRequest.exportChatInviteLink(chatID: chatID)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response)
	}
	
	/**
	Sets the profile photo for the chat, using a `FileLink`.
	*/
	@discardableResult
	public func setChatPhoto(file: MessageFile, chatID: Int) -> Bool {
		
		let request = TelegramRequest.setChatPhoto(chatID: chatID, file: file)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response) ?? false
	}
	
	/**
	Deletes the currently set chat photo.
	*/
	@discardableResult
	public func deleteChatPhoto(chatID: Int) -> Bool {
		
		let request = TelegramRequest.deleteChatPhoto(chatID: chatID)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response) ?? false
	}
	
	/**
	Sets the chat name/title.
	*/
	@discardableResult
	public func setChatTitle(_ title: String, chatID: Int) -> Bool {
		
		let request = TelegramRequest.setChatTitle(chatID: chatID, title: title)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response) ?? false
	}
	
	/**
	Sets the chat description.
	*/
	@discardableResult
	public func setChatDescription(_ description: String, chatID: Int) -> Bool {
		
		let request = TelegramRequest.setChatDescription(chatID: chatID, description: description)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response) ?? false
	}
	
	/**
	Pins a message using the given message ID.
	*/
	@discardableResult
	public func pinMessage(messageID: Int, chatID: Int, disableNotification: Bool = false) -> Bool {
		
		let request = TelegramRequest.pinChatMessage(chatID: chatID, messageID: messageID, disableNotification: disableNotification)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response) ?? false
	}
	
	/**
	Unpins the currently pinned message.
	*/
	@discardableResult
	public func unpinMessage(chatID: Int) -> Bool {
		
		let request = TelegramRequest.unpinChatMessage(chatID: chatID)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response) ?? false
	}
}