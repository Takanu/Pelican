//
//  Chat.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/**
Defines the type of chat that a Chat type represents.
*/
public enum ChatType: String, Codable {
	
	/// Identifies the chat as a 1 on 1 conversation between the bot and a single user.
	case `private`
	
	/// Identifies the chat as a standard group, without supergroup functionality.
	case group
	
	/// Identifies the chat as a supergroup.
	case supergroup
	
	/// Identifies the chat as a channel.
	case channel
}


/**
Represents a Telegram chat.  Includes private chats, any kind of supergroup and channels.
*/
public struct Chat: TelegramType, Codable {
	
	/// Unique identifier for the chat, 52-bit integer when received.
	public var tgID: String
	
	/// Type of chat, can be either "private", "group", "supergroup", or "channel".
	public var type: ChatType
	
	/// Title, for supergroups, channels and group chats.
	public var title: String?
	
	/// Username, for private chats, supergroups and channels if available.
	public var username: String?
	
	/// First name of the other participant in a private chat.
	public var firstName: String?
	
	/// Last name of the other participant in a private chat.
	public var lastName: String?
	
	/// True if a group has "All Members Are Admins" enabled.
	public var areAllMembersAdmins: Bool?
	
	/// The profile picture used to represent the chat. Will only be returned only in the `getChat` method.
	public var photo: ChatPhoto?
	
	/// The description of the group for supergroups and channel-type chats. Will only be returned only in the `getChat` method.
	public var description: String?
	
	/// The chat invite link for supergroups and channel-type chats. Will only be returned only in the `getChat` method.
	public var inviteLink: String?
	
	/// The pinned message for supergroups and channel-type chats. Will only be returned only in the `getChat` method.
	public var pinnedMessage: String?
	
	/// The name of the group's sticker set (for supergroups).  Will only be returned only in the `getChat` method.
	public var stickerSetName: String?
	
	/// Whether a bot is able to change the group sticket set.  Will only be returned only in the `getChat` method.
	public var canSetStickerSet: Bool?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case tgID = "id"
		case type
		case title
		case username
		case firstName = "first_name"
		case lastName = "last_name"
		case areAllMembersAdmins = "all_members_are_administrators"
		case photo
		case description
		case inviteLink = "invite_link"
		case pinnedMessage = "pinned_message"
		case stickerSetName = "sticker_set_name"
		case canSetStickerSet = "can_set_sticker_set"
	}
	
	
	public init(id: String, type: ChatType) {
		self.tgID = id
		self.type = type
	}
	
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		
		tgID = try String(values.decode(Int.self, forKey: .tgID))
		type = try values.decode(ChatType.self, forKey: .type)
		title = try values.decodeIfPresent(String.self, forKey: .title)
		username = try values.decodeIfPresent(String.self, forKey: .username)
		firstName = try values.decodeIfPresent(String.self, forKey: .firstName)
		lastName = try values.decodeIfPresent(String.self, forKey: .lastName)
		
		areAllMembersAdmins = try values.decodeIfPresent(Bool.self, forKey: .areAllMembersAdmins)
		photo = try values.decodeIfPresent(ChatPhoto.self, forKey: .photo)
		description = try values.decodeIfPresent(String.self, forKey: .description)
		inviteLink = try values.decodeIfPresent(String.self, forKey: .inviteLink)
		pinnedMessage = try values.decodeIfPresent(String.self, forKey: .pinnedMessage)
		stickerSetName = try values.decodeIfPresent(String.self, forKey: .stickerSetName)
		canSetStickerSet = try values.decodeIfPresent(Bool.self, forKey: .canSetStickerSet)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		let intID = Int(tgID)
		try container.encode(intID, forKey: .tgID)
		try container.encode(type, forKey: .type)
		try container.encodeIfPresent(title, forKey: .title)
		try container.encodeIfPresent(username, forKey: .username)
		try container.encodeIfPresent(firstName, forKey: .firstName)
		try container.encodeIfPresent(lastName, forKey: .lastName)
		
		try container.encodeIfPresent(areAllMembersAdmins, forKey: .areAllMembersAdmins)
		try container.encodeIfPresent(photo, forKey: .photo)
		try container.encodeIfPresent(description, forKey: .description)
		try container.encodeIfPresent(inviteLink, forKey: .inviteLink)
		try container.encodeIfPresent(pinnedMessage, forKey: .pinnedMessage)
		try container.encodeIfPresent(stickerSetName, forKey: .stickerSetName)
		try container.encodeIfPresent(canSetStickerSet, forKey: .canSetStickerSet)
		
	}
}
