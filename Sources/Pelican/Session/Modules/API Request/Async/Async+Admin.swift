//
//  Async+Admin.swift
//  Pelican
//
//  Created by Ido Constantine on 22/03/2018.
//

import Foundation

/**
This extension handles any kinds of operations involving group moderation and how the group details are presented and changed.
*/
extension MethodRequestAsync {
	
	/**
	Kicks a user from the chat.
	*/
	public func kickUser(_ userID: String, chatID: String, callback: CallbackBoolean = nil) {
		
		let request = TelegramRequest.kickChatMember(chatID: chatID, userID: userID)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response) ?? false)
			}
		}
	}
	
	/**
	Unbans a user from the chat.
	*/
	public func unbanUser(_ userID: String, chatID: String, callback: CallbackBoolean = nil) {
		
		let request = TelegramRequest.unbanChatMember(chatID: chatID, userID: userID)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response) ?? false)
			}
		}
	}
	
	/**
	Applies chat restrictions to a user.
	*/
	public func restrictUser(_ userID: String,
													 chatID: String,
													 restrictUntil: Int?,
													 restrictions: (msg: Bool, media: Bool, stickers: Bool, useWebPreview: Bool)?,
													 callback: CallbackBoolean = nil) {
		
		let request = TelegramRequest.restrictChatMember(chatID: chatID, userID: userID, restrictUntil: restrictUntil, restrictions: restrictions)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response) ?? false)
			}
		}
	}
	
	/**
	Promotes a user to an admin, while being able to define the privileges they have.
	*/
	public func promoteUser(_ userID: String,
														chatID: String,
														rights: (info: Bool, msg: Bool, edit: Bool, delete: Bool, invite: Bool, restrict: Bool, pin: Bool, promote: Bool)?,
													callback: CallbackBoolean = nil) {
		
		let request = TelegramRequest.promoteChatMember(chatID: chatID, userID: userID, rights: rights)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response) ?? false)
			}
		}
	}
	
	/**
	Returns an already existing invite link, or generates one if none currently exist.
	*/
	public func getInviteLink(chatID: String, callback: CallbackString = nil) {
		
		let request = TelegramRequest.exportChatInviteLink(chatID: chatID)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response))
			}
		}
	}
	
	/**
	Sets the profile photo for the chat, using a `FileLink`.
	*/
	public func setChatPhoto(file: MessageFile, chatID: String, callback: CallbackBoolean = nil) {
		
		let request = TelegramRequest.setChatPhoto(chatID: chatID, file: file)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response) ?? false)
			}
		}
	}
	
	/**
	Deletes the currently set chat photo.
	*/
	public func deleteChatPhoto(chatID: String, callback: CallbackBoolean = nil) {
		
		let request = TelegramRequest.deleteChatPhoto(chatID: chatID)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response) ?? false)
			}
		}
	}
	
	/**
	Sets the chat name/title.
	*/
	public func setChatTitle(_ title: String, chatID: String, callback: CallbackBoolean = nil) {
		
		let request = TelegramRequest.setChatTitle(chatID: chatID, title: title)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response) ?? false)
			}
		}
	}
	
	/**
	Sets the chat description.
	*/
	public func setChatDescription(_ description: String, chatID: String, callback: CallbackBoolean = nil) {
		
		let request = TelegramRequest.setChatDescription(chatID: chatID, description: description)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response) ?? false)
			}
		}
	}
	
	/**
	Pins a message using the given message ID.
	*/
	public func pinMessage(messageID: Int, chatID: String, disableNotification: Bool = false, callback: CallbackBoolean = nil) {
		
		let request = TelegramRequest.pinChatMessage(chatID: chatID, messageID: messageID, disableNotification: disableNotification)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response) ?? false)
			}
		}
	}
	
	/**
	Unpins the currently pinned message.
	*/
	public func unpinMessage(chatID: String, callback: CallbackBoolean = nil) {
		
		let request = TelegramRequest.unpinChatMessage(chatID: chatID)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response) ?? false)
			}
		}
	}
}
