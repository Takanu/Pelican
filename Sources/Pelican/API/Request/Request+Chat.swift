//
//  Request+Get.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 10/07/2017.
//
//

import Foundation


/**
Adds an extension that deals in fetching information from Telegram.
*/
extension TelegramRequest {
	
	/* Use this method for your bot to leave a group, supergroup or channel. Returns True on success. */
	public func leaveChat(chatID: String, userID: String) {
		
		query = [
			"chat_id": Int(chatID),
			"user_id": Int(userID),
		]
		
		// Set the Request, Method and Content
		method = "leaveChat"
		
	}
	
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to get up to date information about the chat (current name of the user for one-on-one conversations, 
	current username of a user, group or channel, etc.). Returns a Chat object on success.
	*/
	public static func getChat(chatID: String) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": Int(chatID),
		]
		
		// Set the Request, Method and Content
		request.method = "getChat"
		
		return request
		
	}
	
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to get a list of administrators in a chat. On success, returns an Array of ChatMember objects that 
	contains information about all chat administrators except other bots. If the chat is a group or a supergroup and 
	no administrators were appointed, only the creator will be returned.
	*/
	public static func getChatAdministrators(chatID: String) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": Int(chatID),
		]
		
		// Set the Request, Method and Content
		request.method = "getChatAdministrators"
		
		return request
		
	}
	
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to get the number of members in a chat. Returns Int on success.
	*/
	public static func getChatMemberCount(chatID: String) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": Int(chatID),
		]
		
		// Set the Request, Method and Content
		request.method = "getChatMembersCount"
		
		return request
		
	}
	
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to get information about a member of a chat. Returns a ChatMember object on success.
	*/
	public static func getChatMember(chatID: String, userID: String) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id": Int(chatID),
			"user_id": Int(userID),
		]
		
		// Set the Request, Method and Content
		request.method = "getChatMember"
		
		return request
		
	}
	
}
