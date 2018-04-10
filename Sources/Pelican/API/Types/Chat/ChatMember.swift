//
//  ChatMember.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/**
Defines the status of a chat member, in a group.
*/
public enum ChatMemberStatus: String, Codable {
	case creator = "creator", administrator, member, restricted, left, kicked
}

/**
Contains information about one member of a chat.
*/
public struct ChatMember: Codable {
	
	// BASIC INFORMATION
	/// Information about the user.
	public var user: User
	
	/// The member's status in the chat.
	public var status: ChatMemberStatus
	
	/// The date when restrictions will be lifted for this user (if their `status` is "restricted"), in unix time.
	public var restrictedUntilDate: Int?
	
	/// If true, the bot is able to edit administrator priviliges of that user.
	public var isEditable: Bool?
	
	
	// ADMINISTRATOR PRIVILEGES
	/// If true, this administrator can change the chat title, chat photo and other settings.
	public var canChangeInfo: Bool?
	
	/// If true, this administrator can post in the channel (applies to channels only).
	public var canPostChannelMessages: Bool?
	
	/// If true, this administrator can edit the messages of other users and pin messages (applies to channels only).
	public var canEditChannelMessages: Bool?
	
	/// If true, this administrator can delete messages that other users have posted to the chat.
	public var canDeleteMessages: Bool?
	
	/// If true, this administrator can invite new users to the chat.
	public var canInviteUsers: Bool?
	
	/// If true, this administrator can restrict, ban or unban chat members.
	public var canRestrictMembers: Bool?
	
	/// If true, this administrator can pin messages.
	public var canPinMessages: Bool?
	
	/**
	If true, this administrator can add new administrators with a subset of his own privileges or demote administrators that he has promoted, directly or indirectly (promoted by administrators that were appointed by the user).
	*/
	public var canPromoteMembers: Bool?
	
	
	// MEMBER RESTRICTIONS
	/// If true, the user can send text messages, contacts, locations and venues to the chat.
	public var canSendMessages: Bool?
	
	/// If true, the user can send audio files, documents, photos, videos, video notes and voice notes.  For this to be true, `canSendMessages` must also be true.
	public var canSendMediaMessages: Bool?
	
	/// If true, the user can send animations, games, stickers as well as use inline bots.  For this to be true, 'canSendMediaMessages' must also be true.
	public var canSendOtherMessages: Bool?
	
	/// If true, the user may add web page previews to his messages.  For this to be true, 'canSendOtherMessages' must also be true.
	public var canAddWebPagePreviews: Bool?
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case user
		case status
		case restrictedUntilDate = "until_date"
		case isEditable = "can_be_edited"
		
		case canChangeInfo = "can_change_info"
		case canPostChannelMessages = "can_post_messages"
		case canEditChannelMessages = "can_edit_messages"
		case canDeleteMessages = "can_delete_messages"
		case canInviteUsers = "can_invite_users"
		case canRestrictMembers = "can_restrict_members"
		case canPinMessages = "can_pin_messages"
		case canPromoteMembers = "can_promote_members"
		
		case canSendMessages = "can_send_messages"
		case canSendMediaMessages = "can_send_media_messages"
		case canSendOtherMessages = "can_send_other_messages"
		case canAddWebPagePreviews = "can_add_web_page_previews"
	}
	
	public init(user: User, status: ChatMemberStatus) {
		self.user = user
		self.status = status
	}
	
}
