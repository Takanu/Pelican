//
//  MethodRequestAsync+Send.swift
//  Pelican
//
//  Created by Ido Constantine on 18/03/2018.
//

import Foundation

extension MethodRequestAsync {
	
	/**
	A basic function for testing authorisation tokens, that returns your bot as a user if successful.
	*/
	func getMe(callback: ((User?) -> ())? = nil) {
		
		let request = TelegramRequest.getMe()
		tag.sendAsyncRequest(request) { response in
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response))
			}
		}
	}
	
	/**
	Sends a text-based message to the chat linked to this session.
	*/
	public func sendMessage(_ message: String,
													markup: MarkupType?,
													chatID: Int,
													parseMode: MessageParseMode = .markdown,
													replyID: Int = 0,
													useWebPreview: Bool = false,
													disableNotification: Bool = false,
													callback: ((Message?) -> ())? = nil) {
		
		let request = TelegramRequest.sendMessage(chatID: chatID,
																							text: message,
																							markup: markup,
																							parseMode: parseMode,
																							disableWebPreview: useWebPreview,
																							disableNotification: disableNotification,
																							replyMessageID: replyID)
		
		tag.sendAsyncRequest(request) { response in
			
			// Define the type we wish to decode and see if we can make it happen.
			let message: Message?
			if response != nil {
				message = MethodRequest.decodeResponse(response!)
			} else {
				message = nil
			}
			
			// If we have a callback, return whatever the result was.
			if callback != nil {
				callback!(message)
			}
		}
	}
	
	/**
	Forward a message of any kind.
	*/
	public func forwardMessage(toChatID: Int,
														 fromChatID: Int,
														 fromMessageID: Int,
														 disableNotification: Bool = false,
														 callback: ((Message?) -> ())? = nil) {
		
		let request = TelegramRequest.forwardMessage(toChatID: toChatID, fromChatID: fromChatID, fromMessageID: fromMessageID, disableNotification: disableNotification)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response))
			}
		}
	}
	
	/**
	Sends and uploads a file as a message to the chat linked to this session, using a `MessageFile` type.
	*/
	public func sendFile(_ file: MessageFile,
											 caption: String,
											 markup: MarkupType?,
											 chatID: Int,
											 replyID: Int = 0,
											 disableNotification: Bool = false,
											 callback: ((Message?) -> ())? = nil) {
		
		let request = TelegramRequest.sendFile(file: file,
																					 chatID: chatID,
																					 markup: markup,
																					 caption: caption,
																					 disableNotification: disableNotification,
																					 replyMessageID: replyID)
		
		// If we immediately fail to make the request, call the callback early.
		if request == nil {
			if callback != nil {
				callback!(nil)
				return
			}
		}
		
		tag.sendAsyncRequest(request!) { response in
			
			// If we have a callback, return whatever the result was.
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response!))
			}
		}
	}
	
	
	/**
	Use this method when you need to tell the user that something is happening on the bot's side. The status is set for 5 seconds or less (when a message arrives from your bot, Telegram clients clear its typing status).
	- returns: True on success.
	*/
	public func sendChatAction(_ actionType: ChatAction, chatID: Int, callback: ((Bool) -> ())? = nil) {
		
		let request = TelegramRequest.sendChatAction(action: actionType, chatID: chatID)
		tag.sendAsyncRequest(request) { response in
			
			// Define the type we wish to decode and see if we can make it happen.
			let returnValue: Bool
			returnValue = MethodRequest.decodeResponse(response!) ?? false
			
			// If we have a callback, return whatever the result was.
			if callback != nil {
				callback!(returnValue)
			}
		}
	}
	
	
	/**
	Returns a list of profile pictures for the specified user.
	*/
	public func getUserProfilePhotos(userID: Int,
																	 offset: Int = 0,
																	 limit: Int = 100,
																	 callback: ((UserProfilePhotos?) -> ())? = nil) {
		
		let request = TelegramRequest.getUserProfilePhotos(userID: userID, offset: offset, limit: limit)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response))
			}
		}
	}
	
	/**
	Use this method to get basic info about a file and prepare it for downloading. For the moment, bots can download files of up to 20MB in size. On success, a File object is returned. The file can then be downloaded via the link
	https://api.telegram.org/file/bot<token>/<file_path>, where <file_path> is taken from the response. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling
	getFile again.
	*/
	public func getFile(fileID: String,
											callback: ((FileDownload?) -> ())? = nil) {
		
		let request = TelegramRequest.getFile(fileID: fileID)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response))
			}
		}
	}
	
}

