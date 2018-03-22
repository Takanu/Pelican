//
//  Request+Extra.swift
//  Pelican
//
//  Created by Takanu Kyriako on 15/03/2018.
//

import Foundation

extension TelegramRequest {
	
	/**
	Convenience function for encoding data from an API type to Data.
	- parameter data: The instance you wish to convert into JSON data.
	- returns: The converted type if true, or nil if not.
	- note: The function will log an error to `PLog` if it didn't succeed.
	*/
	static public func encodeDataToUTF8<T: Encodable>(_ object: T) -> String? {
		var jsonData = Data()
		
		do {
			jsonData = try JSONEncoder().encode(object)
		} catch {
			PLog.error("Telegram Request Serialisation Error - \(error)")
			return nil
		}
		
		return String(data: jsonData, encoding: .utf8)
	}
	
	static func encodeMarkupTypeToUTF8(_ markup: MarkupType) -> String? {
		var jsonData = Data()
		
		if markup is MarkupInline {
			let object = markup as! MarkupInline
			do {
				jsonData = try JSONEncoder().encode(object)
			} catch {
				PLog.error("Telegram Request Serialisation Error - \(error)")
				return nil
			}
			
			return String(data: jsonData, encoding: .utf8)
		}
			
		else if markup is MarkupKeyboard {
			let object = markup as! MarkupKeyboard
			do {
				jsonData = try JSONEncoder().encode(object)
			} catch {
				PLog.error("Telegram Request Serialisation Error - \(error)")
				return nil
			}
			
			return String(data: jsonData, encoding: .utf8)
		}
			
		else if markup is MarkupKeyboardRemove {
			let object = markup as! MarkupKeyboardRemove
			do {
				jsonData = try JSONEncoder().encode(object)
			} catch {
				PLog.error("Telegram Request Serialisation Error - \(error)")
				return nil
			}
			
			return String(data: jsonData, encoding: .utf8)
		}
			
		else if markup is MarkupForceReply {
			let object = markup as! MarkupForceReply
			do {
				jsonData = try JSONEncoder().encode(object)
			} catch {
				PLog.error("Telegram Request Serialisation Error - \(error)")
				return nil
			}
			
			return String(data: jsonData, encoding: .utf8)
		}
		
		return nil
	}
	
	
	
	
	
	/* Use this method for your bot to leave a group, supergroup or channel. Returns True on success. */
	public func leaveChat(chatID: Int, userID: Int) {
		
		query = [
			"chat_id":chatID,
			"user_id": userID
		]
		
		// Set the Request, Method and Content
		method = "leaveChat"
		
	}
	
	
	/**
	Use this method to delete a message. A message can only be deleted if it was sent less than 48 hours ago.
	
	- note: Any such recently sent outgoing message may be deleted. Additionally, if the bot is an administrator in a group chat, it can delete any message. If the bot is an administrator in a supergroup, it can delete messages from any other user and service messages about people joining or leaving the group (other types of service messages may only be removed by the group creator). In channels, bots can only remove their own messages.
	*/
	public func deleteMessage(chatID: Int, messageID: Int) {
		
		query = [
			"chat_id":chatID,
			"message_id":messageID
		]
		
		// Set the query
		method = "deleteMessage"
		
	}
	
}

