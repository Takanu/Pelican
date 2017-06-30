//
//  Pelican+Update.swift
//  party
//
//  Created by Ido Constantine on 29/06/2017.
//
//

import Foundation
import Vapor


/**
Defines convenience iteration and string extraction methods for UpdateType and it's derivatives.
*/
public protocol UpdateCollection : Hashable {
	
	func string() -> String
}

extension UpdateCollection {
	static func cases() -> AnySequence<Self> {
		typealias S = Self
		return AnySequence { () -> AnyIterator<S> in
			var raw = 0
			return AnyIterator {
				let current : Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: S.self, capacity: 1) { $0.pointee } }
				guard current.hashValue == raw else { return nil }
				raw += 1
				return current
			}
		}
	}
}

/**
Categorises the types of requests that can be made by a user to the bot.
*/
public enum UpdateType: String, UpdateCollection {
	case message
	case editedMessage = "edited_message"
	case channelPost = "channel_post"
	case editedChannelPost = "edited_channel_post"
	case callbackQuery = "callback_query"
	case inlineQuery = "inline_query"
	case chosenInlineResult = "chosen_inline_result"
	
	public func string() -> String {
		return rawValue
	}
}

public enum ChatUpdateType: String, UpdateCollection {
	case message
	case editedMessage = "edited_message"
	case channelPost = "channel_post"
	case editedChannelPost = "edited_channel_post"
	case callbackQuery = "callback_query"
	
	public func string() -> String {
		return rawValue
	}
}

public enum UserUpdateType: String, UpdateCollection {
	case inlineQuery = "inline_query"
	case chosenInlineResult = "chosen_inline_result"
	
	public func string() -> String {
		return rawValue
	}
}



/**
Provides a framework for parsing updates to Sessions using the Route system.
*/
public protocol Update {
	
	associatedtype DataType: Hashable
	associatedtype Data
	
	/// The type of data being handled, as an enumerator.
	var type: DataType { get set }
	/// The data package contained in the update.
	var data: Data { get set }
	
	/// The basic package of content provided in the update by the sending user, to be used by Route filters.
	var content: String { get set }
	
	
	func matches(_ pattern: String, types: [String]) -> Bool
}

/**
Provides a framework for parsing chat-specific updates to a ChatSession, using the Route system.
*/
public struct ChatUpdate: Update { 
	
	public var type: ChatUpdateType
	public var data: ChatUpdateModel
	public var content: String
	
	public var from: User?
	public var chatID: Int
	
	init(withData data: ChatUpdateModel) {
		
		self.data = data
		
		// Need to ensure the type can be interpreted as other types (edited messages, channel posts)
		if data is Message {
			
			self.type = .message
			
			let message = data as! Message
			self.chatID = message.chat.tgID
			self.content = message.text ?? ""
			
			if message.from != nil {
				self.from = message.from!
			}
		}
			
		else {
			
			self.type = .callbackQuery
			
			let query = data as! CallbackQuery
			self.chatID = Int(query.chatInstance)!
			self.from = query.from
			self.content = query.data ?? ""
		}
	}
	
	/**
	
	*/
	public func matches(_ pattern: String, types: [String]) -> Bool {
		
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
	}
	
}


/**
Provides a framework for parsing user-specific updates to a UserSession, using the Route system.
*/
public struct UserUpdate: Update {
	
	public var type: UserUpdateType
	public var data: UserUpdateModel
	public var content: String
	
	var from: User
	
	init(withData data: UserUpdateModel) {
		
		self.data = data
		
		if data is InlineQuery {
			
			self.type = .inlineQuery
			
			let query = data as! InlineQuery
			self.type = .inlineQuery
			self.content = query.query
			self.from = query.from
			
		}
			
		else {
			
			self.type = .chosenInlineResult
			
			let result = data as! ChosenInlineResult
			self.type = .chosenInlineResult
			self.content = result.query
			self.from = result.from
		}
	}
	
	public func matches(_ pattern: String, types: [String]) -> Bool {
		
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
	}
}
