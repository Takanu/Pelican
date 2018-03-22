//
//  SessionRequestAsync+Send.swift
//  Pelican
//
//  Created by Ido Constantine on 18/03/2018.
//

import Foundation

extension SessionRequestAsync {
	
	/**
	A basic function for testing authorisation tokens, that returns your bot as a user if successful.
	*/
	func getMe(callback: ((User?) -> ())? ) {
		
		let request = TelegramRequest.getMe()
		tag.sendAsyncRequest(request) { response in
			if callback != nil {
				callback!(SessionRequest.decodeResponse(response))
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
				message = SessionRequest.decodeResponse(response!)
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
														 callback: ((Message?) -> ())? ) {
		
		let request = TelegramRequest.forwardMessage(toChatID: toChatID, fromChatID: fromChatID, fromMessageID: fromMessageID, disableNotification: disableNotification)
		let response = tag.sendSyncRequest(request)
		return SessionRequest.decodeResponse(response!)
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
			
			// Define the type we wish to decode and see if we can make it happen.
			let message: Message?
			if response != nil {
				message = SessionRequest.decodeResponse(response!)
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
	Use this method when you need to tell the user that something is happening on the bot's side. The status is set for 5 seconds or less (when a message arrives from your bot, Telegram clients clear its typing status).
	- returns: True on success.
	*/
	public func sendChatAction(_ actionType: ChatAction, chatID: Int, callback: ((Bool) -> ())? = nil) {
		
		let request = TelegramRequest.sendChatAction(action: actionType, chatID: chatID)
		tag.sendAsyncRequest(request) { response in
			
			// Define the type we wish to decode and see if we can make it happen.
			let returnValue: Bool
			returnValue = SessionRequest.decodeResponse(response!) ?? false
			
			// If we have a callback, return whatever the result was.
			if callback != nil {
				callback!(returnValue)
			}
		}
	}
	
}

