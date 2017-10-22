//
//  Message.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

/**
Defines a message type, and in most cases also contains the contents of that message.
*/
public enum MessageType {
	case audio(Audio)
	case contact(Contact)
	case document(Document)
	case game(Game)
	case photo([Photo])
	case location(Location)
	case sticker(Sticker)
	case venue(Venue)
	case video(Video)
	case voice(Voice)
	case text
	
	/// Returns the name of the type as a string.
	func name() -> String {
		switch self {
		case .audio(_):
			return "audio"
		case .contact(_):
			return "contact"
		case .document(_):
			return "document"
		case .game(_):
			return "game"
		case .photo(_):
			return "photo"
		case .location(_):
			return "location"
		case .sticker(_):
			return "sticker"
		case .venue(_):
			return "venue"
		case .video(_):
			return "video"
		case .voice(_):
			return "voice"
		case .text:
			return "text"
		}
	}
}

/**
I'll deal with this once I find a foolproof way to group this stuff...
*/
/*
public enum MessageStatus {

}
*/

public enum MessageParseMode: String {
	case html = "HTML"
	case markdown = "Markdown"
	case none = ""
}

final public class Message: TelegramType, UpdateModel {
	public var storage = Storage() // Unique message identifier for the database
	
	public var tgID: Int // Unique identifier for the Telegram message.
	public var from: User? // Sender, can be empty for messages sent to channels
	public var date: Int // Date the message was sent, in UNIX time.
	public var chat: Chat // Conversation the message belongs to.
	
	// Message Metadata
	public var forwardFrom: User? // The sender of the original message, if forwarded
	public var forwardFromChat: Chat? // For messages forwarded from a channel, info about the original channel.
	public var forwardedFromMessageID: Int? // For forwarded channel posts, identifier of the original message.
	public var forwardDate: Int? // For forwarded messages, date of the original message sent in UNIX time.
	
	public var replyToMessage: Message? // For replies, the original message.  Note that this object will not contain further fields of this type.
	public var editDate: Int? // Date the message was last edited in UNIX time.
	
	// Message Body
	public var type: MessageType // The type of the message, can be anything that matches the protocol
	public var text: String?
	public var entities: [MessageEntity]? // For text messages, special entities like usernames that appear in the text.
	public var caption: String? // Caption for the document, photo or video, 0-200 characters.
	
	// Status Message Info
	// This should be condensed into a single entity using an enumerator, as a status message can only represent one of these things, right?
	
	public var newChatMembers: [User]?             // A status message specifying information about new users added to the group.
	public var leftChatMember: User?               // A status message specifying information about a user who left the group.
	public var newChatTitle: String?               // A status message specifying the new title for the chat.
	public var newChatPhoto: [Photo]?          // A status message showing the new chat public photo.
	public var deleteChatPhoto: Bool = false       // Service Message: the chat photo was deleted.
	public var groupChatCreated: Bool = false      // Service Message: the group has been created.
	public var supergroupChatCreated: Bool = false // I dont get this field...
	public var channelChatCreated: Bool = false    // I DONT GET THIS EITHER
	public var migrateToChatID: Int?               // The group has been migrated to a supergroup with the specified identifier.  This can be greater than 32-bits so you have been warned...
	public var migrateFromChatID: Int?             // The supergroup has been migrated from a group with the specified identifier.
	public var pinnedMessage: Message?             // Specified message was pinned?
	
	
	public init(id: Int, date: Int, chat:Chat) {
		self.tgID = id
		self.date = date
		self.chat = chat
		self.type = .text
	}
	
	
	// NodeRepresentable conforming methods
	public required init(row: Row) throws {
		
		self.tgID = try row.get("message_id")
		
		// Used to extract the type in a way thats consistent with the context given.
		if let subFrom = row["from"] {
			self.from = try .init(row: Row(subFrom)) as User }
		self.date = try row.get("date")
		
		guard let subChat = row["chat"] else { throw TypeError.ExtractFailed }
		self.chat = try .init(row: Row(subChat)) as Chat
		
		
		// Forward
		if let subForwardFrom = row["forward_from"] {
			self.forwardFrom = try .init(row: Row(subForwardFrom)) as User }
		
		if let subForwardFromChat = row["forward_from_chat"] {
			self.forwardFromChat = try .init(row: Row(subForwardFromChat)) as Chat }
		
		self.forwardedFromMessageID = try row.get("forward_from_message_id")
		self.forwardDate = try row.get("forward_date")
		
		
		// Reply/Edit
		if let subReplyToMessage = row["reply_to_message"] {
			self.replyToMessage = try .init(row: Row(subReplyToMessage)) as Message }
		self.editDate = try row.get("edit_date")
		
		
		// Body
		if let type = row["audio"] {
			self.type = .audio(try .init(row: Row(type)) as Audio) }
			
		else if let type = row["contact"] {
			self.type = .contact(try .init(row: Row(type)) as Contact) }
			
		else if let type = row["document"] {
			self.type = .document(try .init(row: Row(type)) as Document) }
			
		else if let type = row["game"] {
			self.type = .game(try .init(row: Row(type)) as Game) }
			
		else if let type = row["photo"] {
			self.type = .photo(try type.array?.map( { try Photo(row: $0) } ) ?? [])
			//self.type = .photo(try .init(row: Row(type)) as Photo) }
		}
			
		else if let type = row["location"] {
			self.type = .location(try .init(row: Row(type)) as Location) }
			
		else if let type = row["sticker"] {
			self.type = .sticker(try .init(row: Row(type)) as Sticker) }
			
		else if let type = row["venue"] {
			self.type = .venue(try .init(row: Row(type)) as Venue) }
			
		else if let type = row["video"] {
			self.type = .video(try .init(row: Row(type)) as Video) }
			
		else if let type = row["voice"] {
			self.type = .voice(try .init(row: Row(type)) as Voice) }
			
		else { self.type = .text }
		
		
		self.text = try row.get("text")
		if let subEntities = row["entities"] {
			self.entities = try subEntities.array?.map( { try MessageEntity(row: $0) } )
		}
		self.caption = try row.get("caption")
		
		
		// Status Messages
		if let subNewChatMembers = row["new_chat_member"] {
			self.newChatMembers = try subNewChatMembers.array?.map( { try User(row: $0) } ) }
		if let subLeftChatMember = row["left_chat_member"] {
			self.leftChatMember = try .init(row: Row(subLeftChatMember)) as User }
		
		self.newChatTitle = try row.get("new_chat_title")
		if let photoRow = row["new_chat_photo"] {
			self.newChatPhoto = try photoRow.array?.map( { try Photo(row: $0) } )
		}
		self.deleteChatPhoto = try row.get("delete_chat_photo") ?? false
		self.groupChatCreated = try row.get("group_chat_created") ?? false
		self.supergroupChatCreated = try row.get("supergroup_chat_created") ?? false
		self.channelChatCreated = try row.get("channel_chat_created") ?? false
		self.migrateToChatID = try row.get("migrate_to_chat_id")
		self.migrateFromChatID = try row.get("migrate_from_chat_id")
		if let subPinnedMessage = row["pinned_message"] {
			self.pinnedMessage = try .init(row: Row(subPinnedMessage)) as Message
		}
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("message_id", tgID)
		try row.set("from", from)
		try row.set("date", date)
		try row.set("chat", chat)
		
		try row.set("forward_from", forwardFrom)
		try row.set("forward_from_chat", forwardFromChat)
		try row.set("forward_from_message_id", forwardedFromMessageID)
		try row.set("forward_date", forwardDate)
		
		try row.set("reply_to_message", forwardFrom)
		try row.set("edit_date", forwardFromChat)
		
		try row.set("text", text)
		try row.set("entities", entities)
		try row.set("caption", caption)
		
		try row.set("new_chat_member", newChatMembers)
		try row.set("left_chat_member", leftChatMember)
		try row.set("new_chat_title", newChatTitle)
		try row.set("new_chat_photo", newChatPhoto)
		try row.set("delete_chat_photo", deleteChatPhoto)
		try row.set("group_chat_created", groupChatCreated)
		try row.set("supergroup_chat_created", supergroupChatCreated)
		try row.set("channel_chat_created", channelChatCreated)
		try row.set("migrate_to_chat_id", migrateToChatID)
		try row.set("migrate_from_chat_id", migrateFromChatID)
		try row.set("pinned_message", pinnedMessage)
		
		return row
	}
}
