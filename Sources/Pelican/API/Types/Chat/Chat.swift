//
//  Chat.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

/**
Defines the type of chat that a Chat type represents.
*/
public enum ChatType: String {
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
final public class Chat: TelegramType {
	public var storage = Storage() // The type used for the model to identify between database entries
	
	/// Unique identifier for the chat, 52-bit integer when received.
	public var tgID: Int
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
	public var allMembersAdmins: Bool?
	
	public init(id: Int, type: ChatType) {
		self.tgID = id
		self.type = type
	}
	
	// NodeRepresentable conforming methods
	public required init(row: Row) throws {
		
		// Tries to extract depending on what context is being used (I GET IT NOW, CLEVER)
		tgID = try row.get("id")
		type = ChatType(rawValue: row["type"]!.string!)!
		
		title = try row.get("title")
		username = try row.get("username")
		firstName = try row.get("first_name")
		lastName = try row.get("last_name")
		allMembersAdmins = try row.get("all_members_are_administrators")
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("id", tgID)
		try row.set("type", type)
		try row.set("title", title)
		try row.set("username", username)
		try row.set("first_name", firstName)
		try row.set("last_name", lastName)
		try row.set("all_members_are_administrators", allMembersAdmins)
		
		return row
	}
}
