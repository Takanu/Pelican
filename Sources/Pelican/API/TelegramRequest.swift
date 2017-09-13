//
//  TelegramRequest.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 10/07/2017.
//
//

import Foundation
import Vapor
import FluentProvider
import HTTP
import FormData
import Multipart

/**
Catalogues all possible methods that are available in the Telegram API through static functions, whilst 
providing properties for wrapping created function data from within the type to.
*/
public class TelegramRequest {
	
	/// The name of the method to be used with the request, to build a URL at a later date.
	var methodName: String = ""
	/// An optional field for the content that's included to define what the content of the request is, if in a String format.
	var content: Any?
	/// The query dictionary to be used as arguments for the request
	var query: [String:NodeConvertible] = [:]
	/// Form content to be added to the request.  As a general rule, pick the query or the form content.
	var form: [String:FormData.Field] = [:]
	
	public var getMethodName: String { return methodName }
	
	
	init() {}

	
	// Forwards a message of any kind.  On success, the sent Message is returned.
	public func forwardMessage(toChatID: Int, fromChatID: Int, fromMessageID: Int, disableNtf: Bool = false) {
		
		query = [
			"chat_id":toChatID,
			"from_chat_id": fromChatID,
			"message_id": fromMessageID,
			"disable_notification": disableNtf
		]
		
		// Set the query
		methodName = "forwardMessage"
		
	}
	
	
	/* Use this method for your bot to leave a group, supergroup or channel. Returns True on success. */
	public func leaveChat(chatID: Int, userID: Int) {
		
		query = [
			"chat_id":chatID,
			"user_id": userID
		]
		
		// Set the Request, Method and Content
		methodName = "leaveChat"
		
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
		methodName = "deleteMessage"
		
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
		methodName = "answerCallbackQuery"
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
		methodName = "answerInlineQuery"
		content = results as Any
		
	}
	*/
	
}

