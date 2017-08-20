//
//  Admin.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation
import Vapor

/**
A delegate for a session, to send requests to Telegram that correspond with administrating a group.

One of a collection of delegates used to let Sessions make requests to Telegram in a language and format
thats concise, descriptive and direct.
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
