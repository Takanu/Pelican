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
	
	
	// Forwards a message of any kind.  On success, the sent Message is returned.
	public func forwardMessage(toChatID: Int, fromChatID: Int, fromMessageID: Int, disableNotification: Bool = false) {
		
		query = [
			"chat_id":toChatID,
			"from_chat_id": fromChatID,
			"message_id": fromMessageID,
			"disable_notification": disableNotification
		]
		
		// Set the query
		method = "forwardMessage"
		
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
	
	// Already has equivalents in Request+Answer, unsure if this is still needed.
	
	/*
	
	// Send answers to callback queries sent from inline keyboards.
	// The answer will be displayed to the user as a notification at the top of the chat screen or as an alert.
	public func answerCallbackQuery(queryID: String, text: String = "", showAlert: Bool = false, url: String = "", cacheTime: Int = 0) {
	
	query = [
	"callback_query_id":queryID,
	"show_alert": showAlert,
	"cache_time": cacheTime
	]
	
	// Check whether any other query needs to be added
	if text != "" { query["text"] = text }
	if url != "" { query["url"] = url }
	
	// Set the query
	method = "answerCallbackQuery"
	content = text as Any
	
	}
	
	
	// Use this method to send answers to an inline query. On success, True is returned.
	// No more than 50 results per query are allowed.
	public func answerInlineQuery(inlineQueryID: String, results: [InlineResult], cacheTime: Int = 300, isPersonal: Bool = false, nextOffset: Int = 0, switchPM: String = "", switchPMParam: String = "") {
	
	// Build the initial query for the POST request
	query = [
	"inline_query_id": inlineQueryID
	]
	
	// Convert the InlineResult objects into a JSON array
	var resultQuery: [Row] = []
	for result in results {
	var row = try! result.makeRow() as Row
	try! row.removeNullEntries()
	resultQuery.append(row)
	}
	
	// Then serialise it as a query entry
	//query["results"] = try! resultQuery.makeJSON().serialize().toString()
	query["results"] = try! resultQuery.converted(to: JSON.self, in: nil).serialize().makeString()
	
	// Check whether any other query needs to be added
	if cacheTime != 300 { query["cache_time"] = cacheTime }
	if isPersonal != false { query["is_personal"] = isPersonal }
	if nextOffset != 0 { query["next_offset"] = nextOffset }
	if switchPM != "" { query["switch_pm_text"] = switchPM }
	if switchPMParam != "" { query["switch_pm_parameter"] = switchPMParam }
	
	// Set the query
	method = "answerInlineQuery"
	content = results as Any
	
	}
	*/
	
}

