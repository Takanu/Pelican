//
//  ChatMember.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

// Status of a chat member, in a group.
public enum ChatMemberStatus: String {
	case creator = "creator", administrator, member, left, kicked
}

// Contains information about one member of the chat.
final public class ChatMember: Model {
	public var storage = Storage()
	public var user: User
	public var status: ChatMemberStatus // The member's status in the chat. Can be “creator”, “administrator”, “member”, “left” or “kicked”.
	
	public init(user: User, status: ChatMemberStatus) {
		self.user = user
		self.status = status
	}
	
	
	// NodeRepresentable conforming methods
	public required init(row: Row) throws {
		user = try row.get("user")
		let text = try row.get("status") as String
		switch text {
		case ChatMemberStatus.creator.rawValue:
			status = .creator
		case ChatMemberStatus.administrator.rawValue:
			status = .administrator
		case ChatMemberStatus.member.rawValue:
			status = .member
		case ChatMemberStatus.left.rawValue:
			status = .left
		case ChatMemberStatus.kicked.rawValue:
			status = .kicked
		default:
			status = .member
		}
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("user", user)
		try row.set("status", status.rawValue)
		
		return row
	}
}
