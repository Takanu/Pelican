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
	public func kickUser(_ userID: Int, chatID: Int) {
		
		let request = TelegramRequest.kickChatMember(chatID: chatID, userID: userID)
		_ = tag.sendSyncRequest(request)
	}
	
	/**
	Unbans a user from the chat.
	*/
	public func unbanUser(_ userID: Int, chatID: Int) {
		
		let request = TelegramRequest.unbanChatMember(chatID: chatID, userID: userID)
		_ = tag.sendSyncRequest(request)
	}
	
	/**
	Applies chat restrictions to a user.
	*/
	public func restrictUser(_ userID: Int,
													 chatID: Int,
													 restrictUntil: Int?,
													 restrictions: (msg: Bool, media: Bool, stickers: Bool, useWebPreview: Bool)?) {
		
		let request = TelegramRequest.restrictChatMember(chatID: chatID, userID: userID, restrictUntil: restrictUntil, restrictions: restrictions)
		_ = tag.sendSyncRequest(request)
	}
	
	/**
	Promotes a user to an admin, while being able to define the privileges they have.
	*/
	public func promoteUser(_ userID: Int,
													chatID: Int,
													rights: (info: Bool, msg: Bool, edit: Bool, delete: Bool, invite: Bool, restrict: Bool, pin: Bool, promote: Bool)?) {
		
		let request = TelegramRequest.promoteChatMember(chatID: chatID, userID: userID, rights: rights)
		_ = tag.sendSyncRequest(request)
	}
	
	/**
	Returns an already existing invite link, or generates one if none currently exist.
	*/
	public func getInviteLink(chatID: Int) {
		
		let request = TelegramRequest.exportChatInviteLink(chatID: chatID)
		_ = tag.sendSyncRequest(request)
	}
	
	/**
	Sets the profile photo for the chat, using a `FileLink`.
	*/
	public func setChatPhoto(file: MessageFile, chatID: Int) {
		
		let request = TelegramRequest.setChatPhoto(chatID: chatID, file: file)
		_ = tag.sendSyncRequest(request)
	}
	
	/**
	Deletes the currently set chat photo.
	*/
	public func deleteChatPhoto(chatID: Int) {
		
		let request = TelegramRequest.deleteChatPhoto(chatID: chatID)
		_ = tag.sendSyncRequest(request)
	}
	
	/**
	Sets the chat name/title.
	*/
	public func setChatTitle(_ title: String, chatID: Int) {
		
		let request = TelegramRequest.setChatTitle(chatID: chatID, title: title)
		_ = tag.sendSyncRequest(request)
	}
	
	/**
	Sets the chat description.
	*/
	public func setChatDescription(_ description: String, chatID: Int) {
		
		let request = TelegramRequest.setChatDescription(chatID: chatID, description: description)
		_ = tag.sendSyncRequest(request)
	}
	
	/**
	Pins a message using the given message ID.
	*/
	public func pinMessage(messageID: Int, chatID: Int, disableNotification: Bool = false) {
		
		let request = TelegramRequest.pinChatMessage(chatID: chatID, messageID: messageID, disableNotification: disableNotification)
		_ = tag.sendSyncRequest(request)
	}
	
	/**
	Unpins the currently pinned message.
	*/
	public func unpinMessage(chatID: Int) {
		
		let request = TelegramRequest.unpinChatMessage(chatID: chatID)
		_ = tag.sendSyncRequest(request)
	}
}
