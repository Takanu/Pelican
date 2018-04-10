//
//  MethodRequest+Ad,om.swift
//  Pelican
//
//  Created by Takanu Kyriako on 16/12/2017.
//

import Foundation

/**
This extension handles any kinds of operations involving group moderation and how the group details are presented and changed.
*/
extension MethodRequestAsync {
	
	/**
	Kicks a user from the chat.
	*/
	@discardableResult
	public func kickUser(_ userID: String, chatID: String) -> Bool {
		
		let request = TelegramRequest.kickChatMember(chatID: chatID, userID: userID)
		let response = tag.sendSyncRequest(request)
		return MethodRequest.decodeResponse(response) ?? false
	}
	
	/**
	Unbans a user from the chat.
	*/
	@discardableResult
	public func unbanUser(_ userID: String, chatID: String) -> Bool {
		
		let request = TelegramRequest.unbanChatMember(chatID: chatID, userID: userID)
		let response = tag.sendSyncRequest(request)
		return MethodRequest.decodeResponse(response) ?? false
	}
	
	/**
	Applies chat restrictions to a user.
	*/
	@discardableResult
	public func restrictUser(_ userID: String,
													 chatID: String,
													 restrictUntil: Int?,
													 restrictions: (msg: Bool, media: Bool, stickers: Bool, useWebPreview: Bool)?) -> Bool {
		
		let request = TelegramRequest.restrictChatMember(chatID: chatID, userID: userID, restrictUntil: restrictUntil, restrictions: restrictions)
		let response = tag.sendSyncRequest(request)
		return MethodRequest.decodeResponse(response) ?? false
	}
	
	/**
	Promotes a user to an admin, while being able to define the privileges they have.
	*/
	@discardableResult
	public func promoteUser(_ userID: String,
														chatID: String,
														rights: (info: Bool, msg: Bool, edit: Bool, delete: Bool, invite: Bool, restrict: Bool, pin: Bool, promote: Bool)?) -> Bool {
		
		let request = TelegramRequest.promoteChatMember(chatID: chatID, userID: userID, rights: rights)
		let response = tag.sendSyncRequest(request)
		return MethodRequest.decodeResponse(response) ?? false
	}
	
	/**
	Returns an already existing invite link, or generates one if none currently exist.
	*/
	public func getInviteLink(chatID: String) -> String? {
		
		let request = TelegramRequest.exportChatInviteLink(chatID: chatID)
		let response = tag.sendSyncRequest(request)
		return MethodRequest.decodeResponse(response)
	}
	
	/**
	Sets the profile photo for the chat, using a `FileLink`.
	*/
	@discardableResult
	public func setChatPhoto(file: MessageFile, chatID: String) -> Bool {
		
		let request = TelegramRequest.setChatPhoto(chatID: chatID, file: file)
		let response = tag.sendSyncRequest(request)
		return MethodRequest.decodeResponse(response) ?? false
	}
	
	/**
	Deletes the currently set chat photo.
	*/
	@discardableResult
	public func deleteChatPhoto(chatID: String) -> Bool {
		
		let request = TelegramRequest.deleteChatPhoto(chatID: chatID)
		let response = tag.sendSyncRequest(request)
		return MethodRequest.decodeResponse(response) ?? false
	}
	
	/**
	Sets the chat name/title.
	*/
	@discardableResult
	public func setChatTitle(_ title: String, chatID: String) -> Bool {
		
		let request = TelegramRequest.setChatTitle(chatID: chatID, title: title)
		let response = tag.sendSyncRequest(request)
		return MethodRequest.decodeResponse(response) ?? false
	}
	
	/**
	Sets the chat description.
	*/
	@discardableResult
	public func setChatDescription(_ description: String, chatID: String) -> Bool {
		
		let request = TelegramRequest.setChatDescription(chatID: chatID, description: description)
		let response = tag.sendSyncRequest(request)
		return MethodRequest.decodeResponse(response) ?? false
	}
	
	/**
	Pins a message using the given message ID.
	*/
	@discardableResult
	public func pinMessage(messageID: Int, chatID: String, disableNotification: Bool = false) -> Bool {
		
		let request = TelegramRequest.pinChatMessage(chatID: chatID, messageID: messageID, disableNotification: disableNotification)
		let response = tag.sendSyncRequest(request)
		return MethodRequest.decodeResponse(response) ?? false
	}
	
	/**
	Unpins the currently pinned message.
	*/
	@discardableResult
	public func unpinMessage(chatID: String) -> Bool {
		
		let request = TelegramRequest.unpinChatMessage(chatID: chatID)
		let response = tag.sendSyncRequest(request)
		return MethodRequest.decodeResponse(response) ?? false
	}
}
