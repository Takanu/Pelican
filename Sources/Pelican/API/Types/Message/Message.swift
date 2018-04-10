//
//  Message.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation


public class Message: Codable, UpdateModel {
	
	// BASICS
	// Unique identifier for the Telegram message.
	public var tgID: Int
	
	// Sender, can be empty for messages sent to channels
	public var from: User?
	
	// Date the message was sent, in UNIX time.
	public var date: Int
	
	// Conversation the message belongs to.
	public var chat: Chat
	
	
	// MESSAGE METADATA
	/// The sender of the original message, if forwarded
	public var forwardFrom: User?
	
	/// For messages forwarded from a channel, info about the original channel.
	public var forwardFromChat: Chat?
	
	/// For forwarded channel posts, identifier of the original message.
	public var forwardedFromMessageID: Int?
	
	/// For forwarded messages, date of the original message sent in UNIX time.
	public var forwardDate: Int?
	
	/// For replies, the original message.  Note that this object will not contain further fields of this type.
	public var replyToMessage: Message?
	
	/// Date the message was last edited in UNIX time.
	public var editDate: Int?
	
	
	// MESSAGE BODY
	/// The type of the message, can be anything that matches the protocol
	public var type: MessageType
	
	/// If a text message, this text property is the text of that text message.  4096 characters maximum.
	public var text: String?
	
	/// For text messages, this contains special entities like usernames that appear in the text.
	public var entities: [MessageEntity]?
	
	/// Caption for the document, photo or video, 0-200 characters.
	public var caption: String?
	
	/// For captions of files, this contains special entities like usernames that appear in the text.
	public var captionEntities: [MessageEntity]?
	
	
	
	// STATUS MESSAGE INFO
	// This should be condensed into a single entity using an enumerator, as a status message can only represent one of these things, right?
	
	// A status message specifying information about new users added to the group.
	public var newChatMembers: [User]?
	
	// A status message specifying information about a user who left the group.
	public var leftChatMember: User?
	
	// A status message specifying the new title for the chat.
	public var newChatTitle: String?
	
	// A status message showing the new chat public photo.
	public var newChatPhoto: [Photo]?
	
	// Service Message: the chat photo was deleted.
	public var deleteChatPhoto: Bool = false
	
	// Service Message: the group has been created.
	public var groupChatCreated: Bool = false
	
	// I dont get this field...
	public var supergroupChatCreated: Bool = false
	
	// I DONT GET THIS EITHER
	public var channelChatCreated: Bool = false
	
	// The group has been migrated to a supergroup with the specified identifier.  This can be greater than 32-bits so you have been warned...
	public var migrateToChatID: Int?
	
	// The supergroup has been migrated from a group with the specified identifier.
	public var migrateFromChatID: Int?
	
	// Specified message was pinned?
	public var pinnedMessage: Message?
	
	
	// PAYMENT INFO
	public var invoice: Invoice?
	public var successfulPayment: SuccessfulPayment?
	
	
	
	enum CodingKeys: String, CodingKey {
		case tgID = "message_id"
		case from
		case date
		case chat
		
		case forwardFrom = "forward_from"
		case forwardFromChat = "forward_from_chat"
		case forwardedFromMessageID = "forward_from_message_id"
		case forwardDate = "forward_date"
		case replyToMessage = "reply_to_message"
		case editDate = "edit_date"
		
		case type
		case text = "text"
		case entities = "entities"
		case caption
		case captionEntities = "caption_entities"
		
		case newChatMembers = "new_chat_members"
		case leftChatMember = "left_chat_member"
		case newChatTitle = "new_chat_title"
		case newChatPhoto = "new_chat_photo"
		case deleteChatPhoto = "delete_chat_photo"
		case groupChatCreated = "group_chat_created"
		case supergroupChatCreated = "supergroup_chat_created"
		case channelChatCreated = "channel_chat_created"
		case migrateToChatID = "migrate_to_chat_id"
		case migrateFromChatID = "migrate_from_chat_id"
		case pinnedMessage = "pinned_message"
		
		case invoice
		case successfulPayment = "successful_payment"
		
		/// Optional message content keys
		case audio
		case contact
		case document
		case game
		case photo
		case location
		case sticker
		case venue
		case video
		case videoNote = "video_note"
		case voice
	}
	
	
	public init(id: Int, date: Int, chat:Chat) {
		self.tgID = id
		self.date = date
		self.chat = chat
		self.type = .text
	}
	
	public required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		
		tgID = try values.decode(Int.self, forKey: .tgID)
		from = try values.decodeIfPresent(User.self, forKey: .from)
		date = try values.decode(Int.self, forKey: .date)
		chat = try values.decode(Chat.self, forKey: .chat)
		
		forwardFrom = try values.decodeIfPresent(User.self, forKey: .forwardFrom)
		forwardFromChat = try values.decodeIfPresent(Chat.self, forKey: .forwardFromChat)
		forwardedFromMessageID = try values.decodeIfPresent(Int.self, forKey: .forwardedFromMessageID)
		forwardDate = try values.decodeIfPresent(Int.self, forKey: .forwardDate)
		replyToMessage = try values.decodeIfPresent(Message.self, forKey: .replyToMessage)
		editDate = try values.decodeIfPresent(Int.self, forKey: .editDate)
		
		text = try values.decodeIfPresent(String.self, forKey: .text)
		entities = try values.decodeIfPresent([MessageEntity].self, forKey: .entities)
		caption = try values.decodeIfPresent(String.self, forKey: .caption)
		captionEntities = try values.decodeIfPresent([MessageEntity].self, forKey: .captionEntities)
		
		newChatMembers = try values.decodeIfPresent([User].self, forKey: .newChatMembers)
		leftChatMember = try values.decodeIfPresent(User.self, forKey: .leftChatMember)
		newChatTitle = try values.decodeIfPresent(String.self, forKey: .newChatTitle)
		newChatPhoto = try values.decodeIfPresent([Photo].self, forKey: .newChatPhoto)
		deleteChatPhoto = try values.decodeIfPresent(Bool.self, forKey: .deleteChatPhoto) ?? false
		groupChatCreated = try values.decodeIfPresent(Bool.self, forKey: .groupChatCreated) ?? false
		supergroupChatCreated = try values.decodeIfPresent(Bool.self, forKey: .supergroupChatCreated) ?? false
		channelChatCreated = try values.decodeIfPresent(Bool.self, forKey: .channelChatCreated) ?? false
		migrateToChatID = try values.decodeIfPresent(Int.self, forKey: .migrateToChatID)
		migrateFromChatID = try values.decodeIfPresent(Int.self, forKey: .migrateFromChatID)
		pinnedMessage = try values.decodeIfPresent(Message.self, forKey: .pinnedMessage)
		
		invoice = try values.decodeIfPresent(Invoice.self, forKey: .invoice)
		successfulPayment = try values.decodeIfPresent(SuccessfulPayment.self, forKey: .successfulPayment)
		
		// Try to find if there's media content here...
		let mediaKeys = values.allKeys
		
		if mediaKeys.count == 0 {
			type = .text
			return
		}
		
		if mediaKeys.contains(.audio) {
			type = .audio(try values.decode(Audio.self, forKey: .audio))
		}
		
		else if mediaKeys.contains(.contact) {
			type = .contact(try values.decode(Contact.self, forKey: .contact))
		}
		
		else if mediaKeys.contains(.document) {
			type = .document(try values.decode(Document.self, forKey: .document))
		}
		
		else if mediaKeys.contains(.game) {
			type = .game(try values.decode(Game.self, forKey: .game))
		}
		
		else if mediaKeys.contains(.photo) {
			type = .photo(try values.decode([Photo].self, forKey: .photo))
		}
		
		else if mediaKeys.contains(.location) {
			type = .location(try values.decode(Location.self, forKey: .location))
		}
		
		else if mediaKeys.contains(.sticker) {
			type = .sticker(try values.decode(Sticker.self, forKey: .sticker))
		}
		
		else if mediaKeys.contains(.venue) {
			type = .venue(try values.decode(Venue.self, forKey: .venue))
		}
		
		else if mediaKeys.contains(.video) {
			type = .video(try values.decode(Video.self, forKey: .video))
		}
			
		else if mediaKeys.contains(.videoNote) {
			type = .videoNote(try values.decode(VideoNote.self, forKey: .videoNote))
		}
			
		else if mediaKeys.contains(.voice) {
			type = .voice(try values.decode(Voice.self, forKey: .voice))
		}
			
		else {
			type = .text
		}
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(tgID, forKey: .tgID)
		try container.encodeIfPresent(from, forKey: .from)
		try container.encode(date, forKey: .date)
		try container.encode(chat, forKey: .chat)
		
		try container.encodeIfPresent(forwardFrom, forKey: .forwardFrom)
		try container.encodeIfPresent(forwardFromChat, forKey: .forwardFromChat)
		try container.encodeIfPresent(forwardedFromMessageID, forKey: .forwardedFromMessageID)
		try container.encodeIfPresent(forwardDate, forKey: .forwardDate)
		try container.encodeIfPresent(replyToMessage, forKey: .replyToMessage)
		try container.encodeIfPresent(editDate, forKey: .editDate)
		
		try container.encodeIfPresent(entities, forKey: .entities)
		try container.encodeIfPresent(caption, forKey: .caption)
		try container.encodeIfPresent(captionEntities, forKey: .captionEntities)
		
		try container.encodeIfPresent(newChatMembers, forKey: .newChatMembers)
		try container.encodeIfPresent(leftChatMember, forKey: .leftChatMember)
		try container.encodeIfPresent(newChatTitle, forKey: .newChatTitle)
		try container.encodeIfPresent(newChatPhoto, forKey: .newChatPhoto)
		try container.encode(deleteChatPhoto, forKey: .deleteChatPhoto)
		try container.encode(groupChatCreated, forKey: .groupChatCreated)
		try container.encode(supergroupChatCreated, forKey: .supergroupChatCreated)
		try container.encode(channelChatCreated, forKey: .channelChatCreated)
		try container.encodeIfPresent(migrateToChatID, forKey: .migrateToChatID)
		try container.encodeIfPresent(migrateFromChatID, forKey: .migrateFromChatID)
		try container.encodeIfPresent(pinnedMessage, forKey: .pinnedMessage)
		
		try container.encodeIfPresent(invoice, forKey: .invoice)
		try container.encodeIfPresent(successfulPayment, forKey: .successfulPayment)
		
		switch type {
		case .audio(let file):
			try container.encode(file, forKey: .audio)
		case .contact(let file):
			try container.encode(file, forKey: .contact)
		case .document(let file):
			try container.encode(file, forKey: .document)
		case .game(let file):
			try container.encode(file, forKey: .game)
		case .photo(let file):
			try container.encode(file, forKey: .photo)
		case .location(let file):
			try container.encode(file, forKey: .location)
		case .sticker(let file):
			try container.encode(file, forKey: .sticker)
		case .venue(let file):
			try container.encode(file, forKey: .venue)
		case .video(let file):
			try container.encode(file, forKey: .video)
		case .videoNote(let file):
			try container.encode(file, forKey: .videoNote)
		case .voice(let file):
			try container.encode(file, forKey: .voice)
		default:
			try container.encodeIfPresent(text, forKey: .text)
		}
		
	}
	
}
