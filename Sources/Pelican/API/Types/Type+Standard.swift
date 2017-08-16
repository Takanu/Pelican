
import Foundation
import Vapor
import FluentProvider

// Errors related to update processing.  Might merge the two?
enum TGTypeError: String, Error {
  case ExtractFailed = "The extraction failed."
}

/** 
Represents a Telegram user or bot.
*/
final public class User: Model {
  public var storage = Storage() // The type used for the model to identify between database entries
  public var messageTypeName = "user"
	
	/// Unique identifier for the user or bot.
  public var tgID: Int
	/// User's or bot's first name.
  public var firstName: String
	/// (Optional) User's or bot's last name.
  public var lastName: String?
	/// (Optional) User's or bot's username.
  public var username: String?
	/// (Optional) IETF language tag of the user's language.
	public var languageCode: String?
  
  public init(id: Int, firstName: String) {
    self.tgID = id
    self.firstName = firstName
  }
  
  // NodeRepresentable conforming methods to transist to and from storage.
	public required init(row: Row) throws {
		
		// Tries to extract depending on what context is being used (I GET IT NOW, CLEVER)
		tgID = try row.get("id")
		firstName = try row.get("first_name")
		lastName = try row.get("last_name")
		username = try row.get("username")
		languageCode = try row.get("language_code")
		
	}
  
  public func makeRow() throws -> Row {
		var row = Row()
		try row.set("id", tgID)
		try row.set("first_name", firstName)
		try row.set("last_name", lastName)
		try row.set("username", username)
		try row.set("language_code", languageCode)
    return row
  }
}

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

/**
Defines a message type, and in most cases also contains the contents of that message.
*/
public enum MessageType {
  case audio(Audio)
  case contact(Contact)
  case document(Document)
  case game(Game)
  case photo(Photo)
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
	// This should be condensed into a single entity using an enumerator, as a status message can only represent one of these things
	
  public var newChatMembers: [User]?             // A status message specifying information about new users added to the group.
  public var leftChatMember: User?               // A status message specifying information about a user who left the group.
  public var newChatTitle: String?               // A status message specifying the new title for the chat.
  public var newChatPhoto: [PhotoSize]?          // A status message showing the new chat public photo.
  public var deleteChatPhoto: Bool = false       // Service Message: the chat photo was deleted.
  public var groupChatCreated: Bool = false      // Service Message: the group has been created.
  public var supergroupChatCreated: Bool = false // I dont get this field...
  public var channelChatCreated: Bool = false    // I DONT GET THIS EITHER
  public var migrateToChatID: Int?               // The group has been migrated to a supergroup with the specified identifier.  This can be greater than 32-bits so you have been warned...
  public var migrateFromChatID: Int?             // The supergroup has been migrated from a group with the specified identifier.
  public var pinnedMessage: Message?             // Specified message was pinned?
	
	
  init(id: Int, date: Int, chat:Chat) {
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
    
    guard let subChat = row["chat"] else { throw TGTypeError.ExtractFailed }
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
      self.type = .photo(try .init(row: Row(type)) as Photo) }
      
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
			self.newChatPhoto = try photoRow.array?.map( { try PhotoSize(row: $0) } )
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


/// Represents one special entity in a text message, such as a hashtag, username or URL.
public enum MessageEntityType: String {
	
	case mention
	case hashtag
	case botCommand
	case url
	case email
	case textLink
	case textMention
	
	case bold
	case italic
	case code
	case pre
}

final public class MessageEntity: Model {
	public var storage = Storage()
  public var type: MessageEntityType // Type of the entity.  Can be a mention, hashtag, bot command, URL, email, special text formatting or a text mention.
  public var offset: Int // Offset in UTF-16 code units to the start of the entity.
  public var length: Int // Length of the entity in UTF-16 code units.
  public var url: String? // For text links only, will be opened when the user taps on it.
  public var user: User? // For text mentions only, the mentioned user.
  
  
  public init(type: MessageEntityType, offset: Int, length: Int) {
    self.type = type
    self.offset = offset
    self.length = length
  }
	
	/**
	Extracts the piece of text it represents from the message body.
	- returns: The string of the entity if successful, and nil if not.
	*/
	public func extract(fromMessage message: Message) -> String? {
		
		if message.text == nil { return nil }
		let text = message.text!
		
		let encoded = text.utf16
		let encStart = encoded.index(encoded.startIndex, offsetBy: offset)
		let encEnd = encoded.index(encStart, offsetBy: length)
		
		let stringBody = encoded.prefix(upTo: encEnd)
		let finalString = stringBody.suffix(from: encStart)
		
		return String(finalString)
		
	}
  
  // NodeRepresentable conforming methods
  public required init(row: Row) throws {
		type = MessageEntityType(rawValue: row["type"]!.string!.snakeToCamelCase)!
    offset = try row.get("offset")
    length = try row.get("length")
    url = try row.get("url")
    user = try row.get("user")
  }
  
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("type", type)
		try row.set("offset", offset)
		try row.set("length", length)
		try row.set("url", url)
		try row.set("user", user)
		
		return row
	}
}


// This doesn't belong to any Telegram type, just a convenience class for enclosing PhotoSize

final public class Photo: TelegramType, SendType {
  public var storage = Storage()
  public var messageTypeName: String = "photo" // MessageType conforming variable for Message class filtering.
  public var method: String = "/sendPhoto" // SendType conforming variable for use when sent
  public var photos: [PhotoSize] = []
  
  
  public init(photos: [PhotoSize]) {
    self.photos = photos
  }
  
  // SendType conforming methods
  public func getQuery() -> [String:NodeConvertible] {
    let keys: [String:NodeConvertible] = [
			"photo": photos.map( { $0.fileID	})]
    
    return keys
  }
  
  // NodeRepresentable conforming methods
  public required init(row: Row) throws {
		if let photoRow = row["photos"] {
			self.photos = try photoRow.array?.map( { try PhotoSize(row: $0) } ) ?? []
		}
	}
  
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("photos", photos)
		
		return row
	}
}



/// THERES A PROBLEM HERE
final public class PhotoSize: TelegramType {
  public var storage = Storage()
  public var fileID: String // Unique identifier for this file.
  public var width: Int // Photo width
  public var height: Int // Photo height
  public var fileSize: Int? // File size
  
  
  public init(fileID: String, width: Int, height: Int) {
    self.fileID = fileID
    self.width = width
    self.height = height
  }
  
  // NodeRepresentable conforming methods
  public required init(row: Row) throws {
    fileID = try row.get("file_id")
    width = try row.get("width")
    height = try row.get("height")
    fileSize = try row.get("file_size")
  }
  
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("file_id", fileID)
		try row.set("width", width)
		try row.set("height", height)
		try row.set("file_size", fileSize)
		
		return row
	}
}


final public class Audio: TelegramType, SendType {
  public var storage = Storage()
  public var messageTypeName: String = "audio" // MessageType conforming variable for Message class filtering.
  public var method: String = "/sendAudio" // SendType conforming variable for use when sent
  
  public var fileID: String // Unique identifier for the file
  public var duration: Int // Duration of the audio in seconds as defined by the sender
  public var performer: String? // Performer of the audio as defined by the sender or by audio tags
  public var title: String? // Title of the audio as defined by the sender or by audio tags.
  public var mimeType: String? // MIME type of the file as defined by the sender.
  public var fileSize: Int? // File size.
  
  public init(fileID: String, duration: Int = 0) {
    self.fileID = fileID
    self.duration = duration
  }
  
  // SendType conforming methods
  public func getQuery() -> [String:NodeConvertible] {
    var keys: [String:NodeConvertible] = [
      "audio": fileID]
    
    if duration != 0 { keys["duration"] = duration }
    if performer != nil { keys["performer"] = performer }
    if title != nil { keys["title"] = title }
    
    return keys
  }
  
  // Model conforming methods
  public required init(row: Row) throws {
    fileID = try row.get("file_id")
    duration = try row.get("duration")
    performer = try row.get("performer")
    title = try row.get("title")
    mimeType = try row.get("mime_type")
    fileSize = try row.get("file_size")
  }
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("file_id", fileID)
		try row.set("duration", duration)
		try row.set("performer", performer)
		try row.set("title", title)
		try row.set("mime_type", mimeType)
		try row.set("file_size", fileSize)
		
		return row
	}
  
}


final public class Document: TelegramType, SendType {
  public var storage = Storage()
  public var messageTypeName: String = "document" // MessageType conforming variable for Message class filtering.
  public var method: String = "/sendDocument" // SendType conforming variable for use when sent
  
  public var fileID: String // Unique file identifier.
  public var thumb: PhotoSize? // Document thumbnail as defined by the sender.
  public var fileName: String? // Original filename as defined by the sender.
  public var mimeType: String? // MIME type of the file as defined by the sender.
  public var fileSize: String? // File size.
  
  public init(fileID: String) {
    self.fileID = fileID
  }
  
  // SendType conforming methods
  public func getQuery() -> [String:NodeConvertible] {
    let keys: [String:NodeConvertible] = [
      "document": fileID]
    
    return keys
  }
  
  // NodeRepresentable conforming methods
  public required init(row: Row) throws {
    fileID = try row.get("file_id")
    thumb = try row.get("thumb")
    fileName = try row.get("file_name")
    mimeType = try row.get("mime_type")
    fileSize = try row.get("file_size")
  }
  
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("file_id", fileID)
		try row.set("thumb", thumb)
		try row.set("file_name", fileName)
		try row.set("mime_type", mimeType)
		try row.set("file_size", fileSize)
		
		return row
	}
  
}


final public class Sticker: TelegramType, SendType {
  public var storage = Storage()
  public var messageTypeName: String = "sticker" // MessageType conforming variable for Message class filtering.
  public var method: String = "/sendSticker" // SendType conforming variable for use when sent
  
  public var fileID: String // Unique file identifier
  public var width: Int
  public var height: Int
  public var thumb: PhotoSize? // Sticker thumbnail in .webp or .jpg format.
  public var emoji: String? // Emoji associated with the sticker.
  public var fileSize: Int?
  
  public init(fileID: String, width: Int, height: Int) {
    self.fileID = fileID
    self.width = width
    self.height = height
  }
  
  // SendType conforming methods to send itself to Telegram under the provided method.
  public func getQuery() -> [String:NodeConvertible] {
    let keys: [String:NodeConvertible] = [
      "file_id": fileID]
    
    return keys
  }
  
  
  // NodeRepresentable conforming methods
  public required init(row: Row) throws {
    fileID = try row.get("file_id")
    width = try row.get("width")
    height = try row.get("height")
    thumb = try row.get("thumb")
    emoji = try row.get("emoji")
    fileSize = try row.get("file_size")
  }
  
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("file_id", fileID)
		try row.set("width", width)
		try row.set("height", height)
		try row.set("thumb", thumb)
		try row.set("emoji", emoji)
		try row.set("file_size", fileSize)
		
		return row
	}
}

final public class Video: TelegramType, SendType {
  public var storage = Storage()
  public var messageTypeName: String = "video" // MessageType conforming variable for Message class filtering.
  public var method: String = "/sendVideo" // SendType conforming variable for use when sent
  
  public var fileID: String
  public var width: Int
  public var height: Int
  public var duration: Int
  public var thumb: PhotoSize?
  public var mimeType: String?
  public var fileSize: Int?
  
  public init(fileID: String, width: Int, height: Int, duration: Int) {
    self.fileID = fileID
    self.width = width
    self.height = height
    self.duration = duration
  }
  
  
  // SendType conforming methods to send itself to Telegram under the provided method.
  public func getQuery() -> [String:NodeConvertible] {
    var keys: [String:NodeConvertible] = [
      "video": fileID]
    
    if duration != 0 { keys["duration"] = duration }
    if width != 0 { keys["width"] = width }
    if height != 0 { keys["height"] = height }
    
    return keys
  }
  
  // NodeRepresentable conforming methods
  public required init(row: Row) throws {
    fileID = try row.get("file_id")
    width = try row.get("width")
    height = try row.get("height")
    duration = try row.get("duration")
    thumb = try row.get("thumb")
    mimeType = try row.get("mime_type")
    fileSize = try row.get("file_size")
  }
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("file_id", fileID)
		try row.set("width", width)
		try row.set("height", height)
		try row.set("duration", duration)
		try row.set("thumb", thumb)
		try row.set("mime_type", mimeType)
		try row.set("file_size", fileSize)
		
		return row
	}
}

final public class Voice: TelegramType, SendType {
  public var storage = Storage()
  public var messageTypeName: String = "voice" // MessageType conforming variable for Message class filtering.
  public var method: String = "/sendVoice" // SendType conforming variable for use when sent
  
  public var fileID: String
  public var duration: Int
  public var mimeType: String?
  public var fileSize: Int?
  
  public init(fileID: String, duration: Int) {
    self.fileID = fileID
    self.duration = duration
  }
  
  // SendType conforming methods to send itself to Telegram under the provided method.
  public func getQuery() -> [String:NodeConvertible] {
    var keys: [String:NodeConvertible] = [
      "voice": fileID]
    
    if duration != 0 { keys["duration"] = duration }
    
    return keys
  }
  
  // NodeRepresentable conforming methods
  public required init(row: Row) throws {
    fileID = try row.get("file_id")
    duration = try row.get("duration")
    mimeType = try row.get("mime_type")
    fileSize = try row.get("file_size")
  }
  
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("file_id", fileID)
		try row.set("duration", duration)
		try row.set("mime_type", mimeType)
		try row.set("file_size", fileSize)
		
		return row
	}
}


/** 
Represents a VideoNote type, introduced in Telegram 4.0 
*/
final public class VideoNote: TelegramType, SendType {
	public var storage = Storage()
	public var messageTypeName: String = "video_note" // MessageType conforming variable for Message class filtering.
	public var method: String = "/sendVideoNote" // SendType conforming variable for use when sent
	
	public var fileID: String
	public var length: Int
	public var duration: Int
	public var thumb: PhotoSize?
	public var fileSize: Int?
	
	// SendType conforming methods to send itself to Telegram under the provided method.
	public func getQuery() -> [String:NodeConvertible] {
		var keys: [String:NodeConvertible] = [
			"chat_id": fileID]
		
		if duration != 0 { keys["duration"] = duration }
		
		return keys
	}
	
	// NodeRepresentable conforming methods
	public required init(row: Row) throws {
		fileID = try row.get("file_id")
		length = try row.get("length")
		duration = try row.get("duration")
		thumb = try row.get("thumb")
		fileSize = try row.get("file_size")
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("file_id", fileID)
		try row.set("length", length)
		try row.set("duration", duration)
		try row.set("thumb", thumb)
		try row.set("file_size", fileSize)
		
		return row
	}
}

final public class Contact: TelegramType, SendType {
  public var storage = Storage()
  public var messageTypeName: String = "contact" // MessageType conforming variable for Message class filtering.
  public var method: String = "/sendContact" // SendType conforming variable for use when sent
  
  public var phoneNumber: String
  public var firstName: String
  public var lastName: String?
  public var userID: Int?
  
  public init(phoneNumber: String, firstName: String) {
    self.phoneNumber = phoneNumber
    self.firstName = firstName
  }
  
  // SendType conforming methods to send itself to Telegram under the provided method.
  public func getQuery() -> [String:NodeConvertible] {
    var keys: [String:NodeConvertible] = [
      "phone_number": phoneNumber,
      "first_name": firstName
    ]
    
    if lastName != nil { keys["last_name"] = lastName }
    
    return keys
  }
  
  // NodeRepresentable conforming methods
  public required init(row: Row) throws {
    phoneNumber = try row.get("phone_number")
    firstName = try row.get("first_name")
    lastName = try row.get("last_name")
    userID = try row.get("user_id")
  }
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("phone_number", phoneNumber)
		try row.set("first_name", firstName)
		try row.set("last_name", lastName)
		try row.set("user_id", userID)
		
		return row
	}
  
	
}

final public class Location: SendType, Model {
  public var storage = Storage()
  public var messageTypeName: String = "location" // MessageType conforming variable for Message class filtering.
  public var method: String = "/sendLocation" // SendType conforming variable for use when sent
  
  public var latitude: Float
  public var longitude: Float
  
  public init(latitude: Float, longitude: Float) {
    self.latitude = latitude
    self.longitude = longitude
  }
  
  // SendType conforming methods to send itself to Telegram under the provided method.
  public func getQuery() -> [String:NodeConvertible] {
    let keys: [String:NodeConvertible] = [
      "longitude": longitude,
      "latitude": latitude]
    
    return keys
  }
  
  // Model conforming methods
  public required init(row: Row) throws {
    latitude = try row.get("latitude")
    longitude = try row.get("longitude")
  }
  
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("latitude", latitude)
		try row.set("longitude", longitude)
		
		return row
	}
  
}

final public class Venue: TelegramType, SendType {
  public var storage = Storage()
  public var messageTypeName: String = "venue" // MessageType conforming variable for Message class filtering.
  public var method: String = "/sendVenue" // SendType conforming variable for use when sent
  
  public var location: Location
  public var title: String
  public var address: String
  public var foursquareID: String?
  
  public init(location: Location, title: String, address: String) {
    self.location = location
    self.title = title
    self.address = address
  }
  
  // SendType conforming methods to send itself to Telegram under the provided method.
  public func getQuery() -> [String:NodeConvertible] {
    var keys: [String:NodeConvertible] = [
      "latitude": location.latitude,
      "longitude": location.longitude,
      "title": title,
      "address": address
    ]
    
    if foursquareID != nil { keys["foursquare_id"] = foursquareID }
    return keys
  }
  
  // NodeRepresentable conforming methods
  public required init(row: Row) throws {
    location = try row.get("location")
    title = try row.get("title")
    address = try row.get("address")
    foursquareID = try row.get("foursquare_id")
  }
  
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("location", location)
		try row.set("title", title)
		try row.set("address", address)
		try row.set("foursquare_id", foursquareID)
		
		return row
	}
	
}

final public class UserProfilePhotos: Model {
	public var storage = Storage()
  public var totalCount: Int
  public var photos: [[PhotoSize]] = []
  
  public init(photoSets: [PhotoSize]...) {
    for photo in photoSets {
      photos.append(photo)
    }
    totalCount = photos.count
  }
  
  
  // NodeRepresentable conforming methods
  public required init(row: Row) throws {
    totalCount = try row.get("total_count")
		photos = try row.get("photos")
  }
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("total_count", totalCount)
		try row.set("photos", photos)
		
		return row
	}
	
}

/***
 Represents a file ready to be downloaded.  The file can be downloaded via the link https://api.telegram.org/file/bot<token>/<file_path>.  It is guaranteed that the link will be valid for at least one hour.  When the link expires, a new one can be requested by calling getFile.
 */
/*
class File: Model {
  var id: Node?
  var fileID: String
  var fileSize: Int? // File size, if known
  var filePath: String? // File path, use https://api.telegram.org/file/bot<token>/<file_path> to get the file.
  
  init(fileID: String) {
    self.fileID = fileID
  }
  
  // NodeRepresentable conforming methods
  required init(node: Node, in context: Context) throws {
    fileID = try row.get("file_id")
    fileSize = try row.get("file_size")
    filePath = try row.get("file_path")
  }
  
  func makeNode() throws -> Node {
    var keys: [String:NodeRepresentable?] = [
      "file_id": fileID,
      ]
    
    if fileSize != nil { keys["file_size"] = fileSize }
    if filePath != nil { keys["file_path"] = filePath }
    return try Node(node: keys)
  }
  
  func makeNode(context: Context) throws -> Node {
    return try self.makeNode()
  }
  
  // Preparation conforming methods, for creating and deleting a database.
  static func prepare(_ database: Database) throws {
    try database.create("users") { users in
      users.id()
    }
  }
  
  static func revert(_ database: Database) throws {
    try database.delete("users")
  }
}
*/

/**
 This object represents an incoming callback query from a callback button in an inline keyboard.
 
 If the button that originated the query was attached to a message sent by the bot, the field message will be present. If the button was attached to a message sent via the bot (in inline mode), the field inline_message_id will be present. Exactly one of the fields data or game_short_name will be present.
 */

final public class CallbackQuery: Model, UpdateModel {
	public var storage = Storage()
	
  public var id: String								// Unique identifier for the query.
  public var from: User								// The sender of the query.
  public var message: Message?				// message with the callback button that originated from the query.  Won't be available if it's too old.
  public var inlineMessageID: String? // Identifier of the message sent via the bot in inline mode that originated the query.
  public var chatInstance: String			// Global identifier, uniquely corresponding to the chat to which the message with the callback button was sent.  Useful for high scores in games.
  public var data: String?						// Data associated with the callback button.  Be aware that a bad client can send arbitrary data here.
  public var gameShortName: String?		// Short name of a Game to be returned, serves as the unique identifier for the game.
  
  
	public init(id: String, from: User, chatInstance: String) {
    self.id = id
    self.from = from
		self.chatInstance = chatInstance
  }
  
  // NodeRepresentable conforming methods
  public required init(row: Row) throws {
    id = try row.get("id")
		from = try User(row: try row.get("from") )
		message = try Message(row: try row.get("message") )
    inlineMessageID = try row.get("inline_message_id")
    chatInstance = try row.get("chat_instance")
    data = try row.get("data")
    gameShortName = try row.get("game_short_name")
  }
  
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("id", id)
		try row.set("from", from)
		try row.set("message", message)
		try row.set("inline_message_id", inlineMessageID)
		try row.set("chat_instance", chatInstance)
		try row.set("data", data)
		try row.set("game_short_name", gameShortName)
		
		return row
	}
}


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

// Contains information about why a request was unsuccessfull.
final public class ResponseParameters: Model {
	public var storage = Storage()
  public var migrateToChatID: Int? // ???
  public var retryAfter: Int? // ???
  
  public init(retryAfter: Int) {
    self.retryAfter = retryAfter
  }
  
  // NodeRepresentable conforming methods
  public required init(row: Row) throws {
    migrateToChatID = try row.get("migrate_to_chat_id")
    retryAfter = try row.get("retry_after")
  }
  
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("migrate_to_chat_id", migrateToChatID)
		try row.set("retry_after", retryAfter)
		
		return row
	}
}


