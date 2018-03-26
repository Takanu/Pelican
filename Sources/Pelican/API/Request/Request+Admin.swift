//
//  Request+Admin.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 10/07/2017.
//
//

import Foundation

/**
Adds an extension that deals in creating requests for administrating a chat.  The bot must be an administrator to use these requests.
*/
extension TelegramRequest {
	
	/* 
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to kick a user from a group or a supergroup. In the case of supergroups, the user will not be able to return to the group on their own using invite links, etc., unless unbanned first. The bot must be an administrator
	in the group for this to work. Returns True on success.
	*/
	public static func kickChatMember(chatID: Int, userID: Int) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": chatID,
			"user_id": userID
		]
		
		// Set the Request, Method and Content
		request.method = "kickChatMember"
		return request
		
	}

	/* 
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to unban a previously kicked user in a supergroup. The user will not return to the group automatically, but will be able to join via link, etc. The bot must be an administrator in the group for this to work. Returns
	True on success.
	*/
	public static func unbanChatMember(chatID: Int, userID: Int) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": chatID,
			"user_id": userID
		]
		
		// Set the Request, Method and Content
		request.method = "unbanChatMember"
		return request
	}
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to restrict a user in a supergroup. The bot must be an administrator in the supergroup for this to work and must have the appropriate admin rights. Pass True for all boolean parameters to lift restrictions from a
	user. Returns True on success.
	*/
	public static func restrictChatMember(chatID: Int, userID: Int, restrictUntil: Int?, restrictions: (msg: Bool, media: Bool, stickers: Bool, useWebPreview: Bool)?) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": chatID,
			"user_id": userID,
			"until_date": restrictUntil
		]
		
		if restrictUntil != nil { request.query["until_date"] = restrictUntil! }
		if restrictions != nil {
			
			request.query["can_send_messages"] = restrictions!.msg
			request.query["can_send_media_messages"] = restrictions!.media
			request.query["can_send_other_messages"] = restrictions!.stickers
			request.query["can_add_web_page_previews"] = restrictions!.useWebPreview
		}
		
		// Set the Request, Method and Content
		request.method = "restrictChatMember"
		return request
	}
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to promote or demote a user in a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Pass False for all boolean parameters to demote a
	user. Returns True on success.
	*/
	public static func promoteChatMember(chatID: Int, userID: Int, rights: (info: Bool, msg: Bool, edit: Bool, delete: Bool, invite: Bool, restrict: Bool, pin: Bool, promote: Bool)?) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": chatID,
			"user_id": userID,
		]
		
		if rights != nil {
			
			request.query["can_change_info"] = rights!.info
			request.query["can_post_messages"] = rights!.msg
			request.query["can_edit_messages"] = rights!.edit
			request.query["can_delete_messages"] = rights!.delete
			request.query["can_invite_users"] = rights!.invite
			request.query["can_restrict_members"] = rights!.restrict
			request.query["can_pin_messages"] = rights!.pin
			request.query["can_promote_members"] = rights!.promote
		}
		
		// Set the Request, Method and Content
		request.method = "promoteChatMember"
		return request
	}
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to export an invite link to a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns exported invite link as String on success.
	*/
	public static func exportChatInviteLink(chatID: Int) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": chatID
		]
		
		// Set the Request, Method and Content
		request.method = "exportChatInviteLink"
		return request
	}
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to set a new profile photo for the chat. Photos can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.
	
	- note: In regular groups (non-supergroups), this method will only work if the ‘All Members Are Admins’ setting is off in the target group.
	*/
	public static func setChatPhoto(chatID: Int, file: MessageFile) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		//request.form["chat_id"] = Field(name: "chat_id", filename: nil, part: Part(headers: [:], body: String(chatID).bytes))
		//form[link.type.rawValue] = Field(name: link.type.rawValue, filename: link.name, part: Part(headers: [:], body: data!))
		
		// Set the Request, Method and Content
		request.method = "setChatPhoto"
		return request
	}
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to delete a chat photo. Photos can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.
	
	- note: In regular groups (non-supergroups), this method will only work if the ‘All Members Are Admins’ setting is off in the target group.
	*/
	public static func deleteChatPhoto(chatID: Int) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": chatID
		]
		
		// Set the Request, Method and Content
		request.method = "deleteChatPhoto"
		return request
	}
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to change the title of a chat. Titles can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.
	*/
	public static func setChatTitle(chatID: Int, title: String) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": chatID,
			"title": title
		]
		
		// Set the Request, Method and Content
		request.method = "setChatTitle"
		return request
	}
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to change the description of a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.
	*/
	public static func setChatDescription(chatID: Int, description: String) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": chatID,
			"description": description
		]
		
		// Set the Request, Method and Content
		request.method = "setChatTitle"
		return request
	}
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to pin a message in a supergroup. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.
	*/
	public static func pinChatMessage(chatID: Int, messageID: Int, disableNotification: Bool = false) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": chatID,
			"message_id": messageID,
			"disable_notification": disableNotification
		]
		
		// Set the Request, Method and Content
		request.method = "pinChatMessage"
		return request
	}
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to unpin a message in a supergroup chat. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.
	*/
	public static func unpinChatMessage(chatID: Int) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": chatID
		]
		
		// Set the Request, Method and Content
		request.method = "unpinChatMessage"
		return request
	}
	
	
}
