//
//  Keyboard+Actions.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/**
Represents a special action that when sent with a message, will remove any `MarkupKeyboard`
currently active, for either all of or a specified group of users.
*/
final public class MarkupKeyboardRemove: MarkupType, Codable, Equatable {
	
	/// Requests clients to remove the custom keyboard (user will not be able to summon this keyboard)
	var removeKeyboard: Bool = true
	
	/// (Optional) Use this parameter if you want to remove the keyboard from specific users only.
	public var selective: Bool = false
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case removeKeyboard = "remove_keyboard"
		case selective
	}
	
	
	/**
	Creates a `MarkupKeyboardRemove` instance, to remove an active `MarkupKeyboard` from the current chat.
	
	If isSelective is true, the keyboard will only be removed for the targets of the message.
	
	**Targets:**
	1) users that are @mentioned in the text of the Message object;
	2) if the bot's message is a reply (has reply_to_message_id), sender of the original message.
	
	- parameter isSelective: If false, the keyboard will be removed for all users.  If true however, the
	keyboard will only be cleared for the targets you specify.
	*/
	public init(isSelective sel: Bool) {
		selective = sel
	}
	
	public static func ==(lhs: MarkupKeyboardRemove, rhs: MarkupKeyboardRemove) -> Bool {
		if lhs.removeKeyboard != rhs.removeKeyboard { return false }
		if lhs.selective != rhs.selective { return false }
		
		return true
	}
	
}


