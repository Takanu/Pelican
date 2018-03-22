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
	
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to get a list of profile pictures for a user. Returns a UserProfilePhotos object.
	*/
	public static func getUserProfilePhotos(userID: Int, offset: Int = 0, limit: Int = 100) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		// I know this could be neater, figure something else later
		var adjustedLimit = limit
		if limit > 100 { adjustedLimit = 100 }
		
		request.query = [
			"user_id": userID,
			"offset": offset,
			"limit": adjustedLimit
		]
		
		// Set the Request, Method and Content
		request.method = "getUserProfilePhotos"
		
		return request
	}
	
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to get basic info about a file and prepare it for downloading. For the moment, bots can download files of up to 20MB in size. On success, a File object is returned. The file can then be downloaded via the link
	https://api.telegram.org/file/bot<token>/<file_path>, where <file_path> is taken from the response. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling
	getFile again.
	*/
	public static func getFile(fileID: Int) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"file_id": fileID
		]
		
		// Set the Request, Method and Content
		request.method = "getFile"
		request.content = fileID as Any
		
		return request
		
	}
	
	
	/**
	Builds and returns a TelegramRequest for the API method with the given arguments.
	
	## API Description
	Use this method to get up to date information about the chat (current name of the user for one-on-one conversations, 
	current username of a user, group or channel, etc.). Returns a Chat object on success.
	*/
	public static func getChat(chatID: Int) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id":chatID,
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
	public static func getChatAdministrators(chatID: Int) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id":chatID,
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
	public static func getChatMemberCount(chatID: Int) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id":chatID,
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
	public static func getChatMember(chatID: Int, userID: Int) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"chat_id":chatID,
			"user_id": userID
		]
		
		// Set the Request, Method and Content
		request.method = "getChatMember"
		
		return request
		
	}
	
}
