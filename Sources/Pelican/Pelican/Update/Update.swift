//
//  Pelican+Update.swift
//  party
//
//  Created by Takanu Kyriako on 29/06/2017.
//
//

import Foundation
import SwiftyJSON

/**
Encapsulates a single update received from a Telegram bot.
*/
public class Update {
	
	// RAW DATA
	/// The type of data being carried by the update.
	public var type: UpdateType
	
	/// The data package contained in the update as a UpdateModel type.
	public var data: UpdateModel
	
	/// The data package contained in the update as JSON, which you can either access through subscripting the type or directly.
	public var json: JSON
	
	/// The time the update was received by Pelican.
	public var time = Date()
	
	
	// HEADER CONTENT
	/// Defines the unique identifier for the content (not the ID of the entity that contains the content).
	public var id: Int
	
	/// The basic package of content provided in the update by the sending user, to be used by Route filters.
	public var content: String
	
	/// The user who triggered the update.  This only has the potential to unwrap as nil if the message originated from a channel.
	public var from: User?
	
	/// The chat the update came from, if the update is a Message type.  If it isn't, it'll return nil.
	public var chat: Chat?
	
	
	// LINKED SESSIONS
	/** Defines any sessions that were linked to this update.  This occurs when more than one SessionBuilder
	captures the same update, and through the optional `collision` function type on a SessionBuilder, a Builder 
	wanted the relevant session to be linked in the update rather than executed.
	*/
	public var linkedSessions: [Session] = []
	
	/// Contains basic information about the update depending on the
	//public var header: [String:String] = [:]
	
	
	
	init(withData data: UpdateModel, json: JSON, type: UpdateType) {
		
		self.data = data
		self.json = json
		self.type = type
		
		
		// Need to ensure the type can be interpreted as other types (edited messages, channel posts)
		if data is Message {
			
			let message = data as! Message
			self.id = message.tgID
			self.content = message.text ?? ""
			self.chat = message.chat
			
			if message.from != nil {
				self.from = message.from!
			}
		}
			
		else if data is CallbackQuery {
			
			let query = data as! CallbackQuery
			self.id = Int(query.id)!
			self.from = query.from
			self.chat = query.message?.chat
			self.content = query.data ?? ""
			
		}
			
		else if data is InlineQuery {
			
			let query = data as! InlineQuery
			self.id = Int(query.id)!
			self.content = query.query
			self.from = query.from
			
		}
			
		else {
			
			let result = data as! ChosenInlineResult
			self.id = Int(result.resultID)!
			self.content = result.query
			self.from = result.from
		}
	}
	
	
	/* Unable to find a clean way to enable subscripting while converting the requested type 
	into it's original type, then return it as an Any type.  Maybe Swift 4 Codable will help.
	*/
	
	/**
	/**
	Attempts to subscript a node entry into a String result, for quick glancing into the contents of an update.
	*/
	subscript(_ list: String...) -> Any? {
		
		let item = node[list]
		let object = node[list] as Any
		print(object)
		
		return item
	}
	*/

	/**
	
	*/
	
	public func matches(_ pattern: String, types: [String]) -> Bool {
		
		if pattern == content {
			//print("Match found C: .\n\(pattern) - \(content)")
			return true
		}
		
		else {
			//print("Match not found.\n\(pattern) - \(content)")
			return false
		}
		
		// For a simple test, do direct text-matching only.
		
		/*
		let regex = try! NSRegularExpression.init(pattern: pattern)
		let matches = regex.matches(in: content, range: NSRangeFromString(content))
		
		if matches.count > 0 {
			print("Match found C: .\n\(pattern) - \(content)")
			return true
		}
			
		else {
			print("Match not found.\n\(pattern) - \(content)")
			return false
		}
		*/
	}
}
