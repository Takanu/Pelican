//
//  KeyboardForceReply.swift
//  Pelican
//
//  Created by Ido Constantine on 21/12/2017.
//

import Foundation

/**
Represents a special action that when sent with a message, will force Telegram clients to display
a reply interface to all or a selected group of people in the chat.
*/
final public class MarkupForceReply: MarkupType, Codable {
	
	/// Shows reply interface to the user, as if they manually selected the bot‘s message and tapped ’Reply'
	public var forceReply: Bool = true
	
	/// (Optional) Use this parameter if you want to force reply from specific users only.
	public var selective: Bool = false
	
	/**
	Creates a `MarkupForceReply` instance, to force Telegram clients to display
	a reply interface to all or a selected group of people in the chat.
	
	If isSelective is true, the reply interface will only be displayed to targets of the message it is being sent with.
	
	**Targets:**
	1) users that are @mentioned in the text of the Message object;
	2) if the bot's message is a reply (has reply_to_message_id), sender of the original message.
	
	- parameter isSelective: If false, the reply interface will appear for all users.  If true however, the
	reply interface will only appear for the targets you specify.
	*/
	public init(isSelective sel: Bool) {
		selective = sel
	}
}
