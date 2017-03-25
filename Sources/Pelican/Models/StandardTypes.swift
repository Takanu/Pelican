
import Foundation
import Vapor
import Fluent

// Errors related to update processing.  Might merge the two?
enum TGTypeError: String, Error {
    case ExtractFailed = "The extraction failed."
}

// Represents a Telegram bot or user.
public class User: TelegramType {
    public var id: Node? // The type used for the model to identify between database entries
    public var messageTypeName = "user"
    
    public var tgID: Int // Unique identifier for the user or bot
    public var firstName: String // User's or bot's first name
    public var lastName: String? // (Optional) User's or bot's last name
    public var username: String? // (Optional) User's or bot's username
    
    public init(id: Int, firstName: String) {
        self.tgID = id
        self.firstName = firstName
    }
    
    // NodeRepresentable conforming methods to transist to and from storage.
    public required init(node: Node, in context: Context) throws {
        
        // Tries to extract depending on what context is being used (I GET IT NOW, CLEVER)
        switch context {
        case TGContext.response:
            self.tgID = try node.extract("id")
        default:
            self.id = try node.extract("id")
            self.tgID = try node.extract("user_id")
        }
        
        firstName = try node.extract("first_name")
        lastName = try node.extract("last_name")
        username = try node.extract("username")
        
    }
    
    public func makeNode() throws -> Node {
        let keys: [String:NodeRepresentable?] = [
            "id": id,
            "user_id" : tgID,
            "first_name": firstName,
            "last_name": lastName,
            "username": username
            ]

        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        
        switch context {
        case TGContext.response:
            var node = try self.makeNode()
            _ = try node.removeNodeEntry(name: "id")
            _ = try node.renameNodeEntry(from: "user_id", to: "id")
            try node.removeNilValues()
            return node
        default:
            return try self.makeNode()
        }
        
    }
    
    // Preparation conforming methods, for creating and deleting a database.
    public static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
            users.string("user_id")
            users.string("first_name")
            users.string("last_name")
            users.string("username")
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}

public class Chat: TelegramType {
    public var id: Node? // The type used for the model to identify between database entries
    
    public var tgID: Int // Unique identifier for the chat, 52-bit integer when received.
    public var type: String // Type of chat, can be either "private", "group", "supergroup", or "channel".
    public var title: String? // Title, for supergroups, channels and group chats
    public var username: String? // Username, for private chats, supergroups and channels if available.
    public var firstName: String? // First name of the other participant in a private chat
    public var lastName: String? // Last name of the other participant in a private chat
    public var allMembersAdmins: Bool? // True if a group has "All Members Are Admins" enabled.
    
    public init(id idIn: Int, type typeIn: String) {
        tgID = idIn
        type = typeIn
    }
    
    // NodeRepresentable conforming methods
    public required init(node: Node, in context: Context) throws {
        
        // Tries to extract depending on what context is being used (I GET IT NOW, CLEVER)
        switch context {
        case TGContext.response:
            self.tgID = try node.extract("id")
        default:
            self.id = try node.extract("id")
            self.tgID = try node.extract("chat_id")
        }
        
        type = try node.extract("type")
        title = try node.extract("title")
        username = try node.extract("username")
        firstName = try node.extract("first_name")
        lastName = try node.extract("last_name")
        allMembersAdmins = try node.extract("all_members_are_admins")
    }
    
    public func makeNode() throws -> Node {
        let keys: [String:NodeRepresentable?] = [
            "id": id,
            "chat_id": tgID,
            "type": type,
            "username": username,
            "first_name": firstName,
            "last_name": lastName,
            "all_members_are_admins": allMembersAdmins]

        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        switch context {
        case TGContext.response:
            var node = try self.makeNode()
            _ = try node.removeNodeEntry(name: "id")
            _ = try node.renameNodeEntry(from: "chat_id", to: "id")
            try node.removeNilValues()
            return node
        default:
            return try self.makeNode()
        }
    }
    
    // Preparation conforming methods, for creating and deleting a database.
    public static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}

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
}

public class Message: TelegramType {
    public var id: Node? // Unique message identifier for the database
    
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
    public var newChatMember: User?                // A status message specifying information about a new user added to the group.
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
    public required init(node: Node, in context: Context) throws {
        // Tries to extract depending on what context is being used (I GET IT NOW, CLEVER)
        switch context {
        case TGContext.response:
            self.tgID = try node.extract("message_id")
        default:
            self.id = try node.extract("id")
            self.tgID = try node.extract("message_id")
        }
        
        
        // Used to extract the type in a way thats consistent with the context given.
        if let subFrom = node["from"] {
            self.from = try .init(node: subFrom, in: context) as User }
        self.date = try node.extract("date")
        
        guard let subChat = node["chat"] else { throw TGTypeError.ExtractFailed }
        self.chat = try .init(node: subChat, in: context) as Chat
        
        
        // Forward
        if let subForwardFrom = node["forward_from"] {
            self.forwardFrom = try .init(node: subForwardFrom, in: context) as User }
        if let subForwardFromChat = node["forward_from_chat"] {
            self.forwardFromChat = try .init(node: subForwardFromChat, in: context) as Chat }
        self.forwardedFromMessageID = try node.extract("forward_from_message_id")
        self.forwardDate = try node.extract("forward_date")
        
        
        // Reply/Edit
        if let subReplyToMessage = node["reply_to_message"] {
            self.replyToMessage = try .init(node: subReplyToMessage, in: context) as Message }
        self.editDate = try node.extract("edit_date")
        
        
        // Body
        if let type = node["audio"] {
            self.type = .audio(try .init(node: type, in: context) as Audio) }
        
        else if let type = node["contact"] {
            self.type = .contact(try .init(node: type, in: context) as Contact) }
        
        else if let type = node["document"] {
            self.type = .document(try .init(node: type, in: context) as Document) }
        
        else if let type = node["game"] {
            self.type = .game(try .init(node: type, in: context) as Game) }
        
        else if let type = node["photo"] {
            self.type = .photo(try .init(node: type, in: context) as Photo) }
        
        else if let type = node["location"] {
            self.type = .location(try .init(node: type, in: context) as Location) }
        
        else if let type = node["sticker"] {
            self.type = .sticker(try .init(node: type, in: context) as Sticker) }
        
        else if let type = node["venue"] {
            self.type = .venue(try .init(node: type, in: context) as Venue) }
            
        else if let type = node["video"] {
            self.type = .video(try .init(node: type, in: context) as Video) }
            
        else if let type = node["voice"] {
            self.type = .voice(try .init(node: type, in: context) as Voice) }
        
        else { self.type = .text }
        
        self.text = try node.extract("text")
        self.entities = try node.extract("entities")
        self.caption = try node.extract("caption")
        
        
        // Status Messages
        if let subNewChatMember = node["new_chat_member"] {
            self.newChatMember = try .init(node: subNewChatMember, in: context) as User }
        
        if let subLeftChatMember = node["left_chat_member"] {
            self.leftChatMember = try .init(node: subLeftChatMember, in: context) as User }
        
        self.newChatTitle = try node.extract("new_chat_title")
        //self.newChatPhoto = try node.extract("new_chat_photo")
        self.deleteChatPhoto = try node.extract("delete_chat_photo") ?? false
        self.groupChatCreated = try node.extract("group_chat_created") ?? false
        self.supergroupChatCreated = try node.extract("supergroup_chat_created") ?? false
        self.channelChatCreated = try node.extract("channel_chat_created") ?? false
        self.migrateToChatID = try node.extract("migrate_to_chat_id")
        self.migrateFromChatID = try node.extract("migrate_from_chat_id")
        if let subPinnedMessage = node["pinned_message"] {
            self.pinnedMessage = try .init(node: subPinnedMessage, in: context) as Message
        }
    }
 
    public func makeNode() throws -> Node {
        var keys: [String:NodeRepresentable?] = [:]
        keys["id"] = id
        keys["message_id"] = tgID
        keys["from"] = from
        keys["date"] = date
        keys["chat"] = chat
        
        keys["forward_from"] = forwardFrom
        keys["forward_from_chat"] = forwardFromChat
        keys["forward_from_message_id"] = forwardedFromMessageID
        keys["forward_date"] = forwardDate
        
        keys["reply_to_message"] = forwardFrom
        keys["edit_date"] = forwardFromChat
        
        keys["text"] = text
        keys["entities"] = try entities?.makeNode()
        keys["caption"] = caption
        
        keys["new_chat_member"] = newChatMember
        keys["left_chat_member"] = leftChatMember
        keys["new_chat_title"] = newChatTitle
        keys["new_chat_photo"] = try newChatPhoto?.makeNode()
        keys["delete_chat_photo"] = deleteChatPhoto
        keys["group_chat_created"] = groupChatCreated
        keys["supergroup_chat_created"] = supergroupChatCreated
        keys["channel_chat_created"] = channelChatCreated
        keys["migrate_to_chat_id"] = migrateToChatID
        keys["migrate_from_chat_id"] = migrateFromChatID
        keys["pinned_message"] = pinnedMessage
        
        return try Node(node: keys)
    }
 
    public func makeNode(context: Context) throws -> Node {
        switch context {
        case TGContext.response:
            var node = try self.makeNode()
            _ = try node.removeNodeEntry(name: "id")
            _ = try node.renameNodeEntry(from: "message_id", to: "id")
            try node.removeNilValues()
            return node
        default:
            return try self.makeNode()
        }
    }
    
    // Preparation conforming methods, for creating and deleting a database.
    public static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}


// Represents one special entity in a text message, such as a hashtag, username or URL.
public class MessageEntity: NodeConvertible, JSONConvertible {
    public var type: String // Type of the entity.  Can be a mention, hashtag, bot command, URL, email, special text formatting or a text mention.
    public var offset: Int // Offset in UTF-16 code units to the start of the entity.
    public var length: Int // Length of the entity in UTF-16 code units.
    public var url: String? // For text links only, will be opened when the user taps on it.
    public var user: User? // For text mentions only, the mentioned user.
    
    public init(type: String, offset: Int, length: Int) {
        self.type = type
        self.offset = offset
        self.length = length
    }
    
    // NodeRepresentable conforming methods
    public required init(node: Node, in context: Context) throws {
        type = try node.extract("type")
        offset = try node.extract("offset")
        length = try node.extract("length")
        url = try node.extract("url")
        user = try node.extract("user")
    }
    
    public func makeNode() throws -> Node {
        var keys: [String:NodeRepresentable?] = [
            "type": type,
            "offset": offset,
            "length": length]
        
        if url != nil { keys["url"] = url }
        if user != nil { keys["user"] = user }
        
        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}


// This doesn't belong to any Telegram type, just a convenience class for enclosing PhotoSize
public class Photo: TelegramType, SendType {
    public var id: Node?
    
    var messageTypeName: String = "photo" // MessageType conforming variable for Message class filtering.
    public var method: String = "/sendPhoto" // SendType conforming variable for use when sent
    public var photos: [PhotoSize] = []
    
    public init(photos: [PhotoSize]) {
        self.photos = photos
    }
    
    // SendType conforming methods
    public func getQuery() -> [String:CustomStringConvertible] {
        let keys: [String:CustomStringConvertible] = [
            "photo": photos[0].fileID]
        
        return keys
    }
    
    // NodeRepresentable conforming methods
    public required init(node: Node, in context: Context) throws {
        switch context {
        case TGContext.response:
            let array = node.nodeArray!
            for item in array {
                photos.append(try! PhotoSize(node: item, in: context))
            }
        default:
            id = try node.extract("id")
            photos = try node.extract("photos")
        }
        
        
    }
    
    public func makeNode() throws -> Node {
        let keys: [String:NodeRepresentable?] = [
            "id": id,
            "photos": try photos.makeNode()]
        
        return try Node(node:keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
    
    // Preparation conforming methods, for creating and deleting a database.
    public static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}
 


/// THERES A PROBLEM HERE
public class PhotoSize: TelegramType {
    public var id: Node?
    
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
    public required init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        fileID = try node.extract("file_id")
        width = try node.extract("width")
        height = try node.extract("height")
        fileSize = try node.extract("file_size")
    }
    
    public func makeNode() throws -> Node {
        let keys: [String:NodeRepresentable?] = [
            "id": id,
            //"file_id": fileID,
            "width": width,
            "height":height,
            "file_size": fileSize]
        
        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        switch context {
        case TGContext.response:
            var node = try self.makeNode()
            _ = try node.removeNodeEntry(name: "id")
            try node.removeNilValues()
            return node
        default:
            return try self.makeNode()
        }
    }
    
    // Preparation conforming methods, for creating and deleting a database.
    public static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}


public class Audio: TelegramType, SendType {
    public var id: Node?
    var messageTypeName: String = "audio" // MessageType conforming variable for Message class filtering.
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
    public func getQuery() -> [String:CustomStringConvertible] {
        var keys: [String:CustomStringConvertible] = [
            "audio": fileID]
        
        if duration != 0 { keys["duration"] = duration }
        if performer != nil { keys["performer"] = performer }
        if title != nil { keys["title"] = title }
        
        return keys
    }
    
    // NodeRepresentable conforming methods
    public required init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        fileID = try node.extract("file_id")
        duration = try node.extract("duration")
        performer = try node.extract("performer")
        title = try node.extract("title")
        mimeType = try node.extract("mime_type")
        fileSize = try node.extract("file_size")
    }
    
    public func makeNode() throws -> Node {
        let keys: [String:NodeRepresentable?] = [
            "id": id,
            "file_id": fileID,
            "duration": duration,
            "performer": performer,
            "title": title,
            "mime_type": mimeType,
            "file_size": fileSize]
        
        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        switch context {
        case TGContext.response:
            var node = try self.makeNode()
            _ = try node.removeNodeEntry(name: "id")
            try node.removeNilValues()
            return node
        default:
            return try self.makeNode()
        }
    }
    
    // Preparation conforming methods, for creating and deleting a database.
    public static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("users")
    }

}

public class Document: TelegramType, SendType {
    public var id: Node?
    var messageTypeName: String = "document" // MessageType conforming variable for Message class filtering.
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
    public func getQuery() -> [String:CustomStringConvertible] {
        let keys: [String:CustomStringConvertible] = [
            "document": fileID]
        
        return keys
    }
    
    // NodeRepresentable conforming methods
    public required init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        fileID = try node.extract("file_id")
        thumb = try node.extract("thumb")
        fileName = try node.extract("file_name")
        mimeType = try node.extract("mime_type")
        fileSize = try node.extract("file_size")
    }
    
    public func makeNode() throws -> Node {
        let keys: [String:NodeRepresentable?] = [
            "id": id,
            "file_id": fileID,
            "thumb": thumb,
            "file_name": fileName,
            "mime_type": mimeType,
            "file_size": fileSize]
        
        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        switch context {
        case TGContext.response:
            var node = try self.makeNode()
            _ = try node.removeNodeEntry(name: "id")
            try node.removeNilValues()
            return node
        default:
            return try self.makeNode()
        }
    }
    
    // Preparation conforming methods, for creating and deleting a database.
    public static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("users")
    }

}

public class Sticker: TelegramType, SendType {
    public var id: Node?
    var messageTypeName: String = "sticker" // MessageType conforming variable for Message class filtering.
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
    public func getQuery() -> [String:CustomStringConvertible] {
        let keys: [String:CustomStringConvertible] = [
            "file_id": fileID]
        
        return keys
    }
    
    
    // NodeRepresentable conforming methods
    public required init(node: Node, in context: Context) throws {
        fileID = try node.extract("file_id")
        width = try node.extract("width")
        height = try node.extract("height")
        thumb = try node.extract("thumb")
        emoji = try node.extract("emoji")
        fileSize = try node.extract("file_size")
    }
    
    public func makeNode() throws -> Node {
        let keys: [String:NodeRepresentable?] = [
            "id": id,
            "file_id": fileID,
            "width": width,
            "height": height,
            "thumb": thumb,
            "emoji": emoji,
            "file_size": fileSize
        ]
        
        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        switch context {
        case TGContext.response:
            var node = try self.makeNode()
            _ = try node.removeNodeEntry(name: "id")
            try node.removeNilValues()
            return node
        default:
            return try self.makeNode()
        }
    }
    
    // Preparation conforming methods, for creating and deleting a database.
    public static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}

public class Video: TelegramType, SendType {
    public var id: Node?
    var messageTypeName: String = "video" // MessageType conforming variable for Message class filtering.
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
    public func getQuery() -> [String:CustomStringConvertible] {
        var keys: [String:CustomStringConvertible] = [
            "video": fileID]
        
        if duration != 0 { keys["duration"] = duration }
        if width != 0 { keys["width"] = width }
        if height != 0 { keys["height"] = height }

        return keys
    }
    
    // NodeRepresentable conforming methods
    public required init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        fileID = try node.extract("file_id")
        width = try node.extract("width")
        height = try node.extract("height")
        duration = try node.extract("duration")
        thumb = try node.extract("thumb")
        mimeType = try node.extract("mime_type")
        fileSize = try node.extract("file_size")
    }
    
    public func makeNode() throws -> Node {
        let keys: [String:NodeRepresentable?] = [
            "id": id,
            "file_id": fileID,
            "width": width,
            "height": height,
            "duration": duration,
            "thumb": thumb,
            "mime_type": mimeType,
            "file_size": fileSize]
        
        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        switch context {
        case TGContext.response:
            var node = try self.makeNode()
            _ = try node.removeNodeEntry(name: "id")
            try node.removeNilValues()
            return node
        default:
            return try self.makeNode()
        }
    }
    
    // Preparation conforming methods, for creating and deleting a database.
    public static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}

public class Voice: TelegramType, SendType {
    public var id: Node?
    var messageTypeName: String = "voice" // MessageType conforming variable for Message class filtering.
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
    public func getQuery() -> [String:CustomStringConvertible] {
        var keys: [String:CustomStringConvertible] = [
            "voice": fileID]
        
        if duration != 0 { keys["duration"] = duration }
        
        return keys
    }
    
    // NodeRepresentable conforming methods
    public required init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        fileID = try node.extract("file_id")
        duration = try node.extract("duration")
        mimeType = try node.extract("mime_type")
        fileSize = try node.extract("file_size")
    }
    
    public func makeNode() throws -> Node {
        let keys: [String:NodeRepresentable?] = [
            "id": id,
            "file_id": fileID,
            "duration": duration,
            "mime_type": mimeType,
            "file_size": fileSize]
        
        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        switch context {
        case TGContext.response:
            var node = try self.makeNode()
            _ = try node.removeNodeEntry(name: "id")
            try node.removeNilValues()
            return node
        default:
            return try self.makeNode()
        }
    }
    
    // Preparation conforming methods, for creating and deleting a database.
    public static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}

public class Contact: TelegramType, SendType {
    public var id: Node?
    var messageTypeName: String = "contact" // MessageType conforming variable for Message class filtering.
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
    public func getQuery() -> [String:CustomStringConvertible] {
        var keys: [String:CustomStringConvertible] = [
            "phone_number": phoneNumber,
            "first_name": firstName
        ]
        
        if lastName != nil { keys["last_name"] = lastName }
        
        return keys
    }
    
    // NodeRepresentable conforming methods
    public required init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        phoneNumber = try node.extract("phone_number")
        firstName = try node.extract("first_name")
        lastName = try node.extract("last_name")
        userID = try node.extract("user_id")
    }
    
    public func makeNode() throws -> Node {
        let keys: [String:NodeRepresentable?] = [
            "id": id,
            "phone_number": phoneNumber,
            "first_name": firstName,
            "last_name": lastName,
            "user_id": userID
        ]
        
        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        switch context {
        case TGContext.response:
            var node = try self.makeNode()
            _ = try node.removeNodeEntry(name: "id")
            try node.removeNilValues()
            return node
        default:
            return try self.makeNode()
        }
    }
    
    // Preparation conforming methods, for creating and deleting a database.
    public static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}

public class Location: NodeConvertible, JSONConvertible, SendType {
    public var id: Node?
    var messageTypeName: String = "location" // MessageType conforming variable for Message class filtering.
    public var method: String = "/sendLocation" // SendType conforming variable for use when sent
    
    public var latitude: Float
    public var longitude: Float
    
    public init(latitude: Float, longitude: Float) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // SendType conforming methods to send itself to Telegram under the provided method.
    public func getQuery() -> [String:CustomStringConvertible] {
        let keys: [String:CustomStringConvertible] = [
            "longitude": longitude,
            "latitude": latitude]
        
        return keys
    }
    
    // NodeRepresentable conforming methods
    public required init(node: Node, in context: Context) throws {
        latitude = try node.extract("latitude")
        longitude = try node.extract("longitude")
    }
    
    public func makeNode() throws -> Node {
        let keys: [String:NodeRepresentable?] = [
            "id": id,
            "latitude": latitude,
            "longitude": longitude
        ]
        
        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        switch context {
        case TGContext.response:
            var node = try self.makeNode()
            _ = try node.removeNodeEntry(name: "id")
            try node.removeNilValues()
            return node
        default:
            return try self.makeNode()
        }
    }
    
    // Preparation conforming methods, for creating and deleting a database.
    public static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("users")
    }

}

public class Venue: TelegramType, SendType {
    public var id: Node?
    var messageTypeName: String = "venue" // MessageType conforming variable for Message class filtering.
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
    public func getQuery() -> [String:CustomStringConvertible] {
        var keys: [String:CustomStringConvertible] = [
            "latitude": location.latitude,
            "longitude": location.longitude,
            "title": title,
            "address": address
        ]
        
        if foursquareID != nil { keys["foursquare_id"] = foursquareID }
        return keys
    }
    
    // NodeRepresentable conforming methods
    public required init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        location = try node.extract("location")
        title = try node.extract("title")
        address = try node.extract("address")
        foursquareID = try node.extract("foursquare_id")
    }
    
    public func makeNode() throws -> Node {
        let keys: [String:NodeRepresentable?] = [
            "id": id,
            "location": location,
            "title": title,
            "address": address,
            "foursquare_id": foursquareID
        ]
        
        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        switch context {
        case TGContext.response:
            var node = try self.makeNode()
            _ = try node.removeNodeEntry(name: "id")
            try node.removeNilValues()
            return node
        default:
            return try self.makeNode()
        }
    }
    
    // Preparation conforming methods, for creating and deleting a database.
    public static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}

public class UserProfilePhotos: NodeConvertible, JSONConvertible {
    public var totalCount: Int
    public var photos: [[PhotoSize]] = []
    
    public init(photoSets: [PhotoSize]...) {
        for photo in photoSets {
            photos.append(photo)
        }
        totalCount = photos.count
    }
    
    
    // NodeRepresentable conforming methods
    public required init(node: Node, in context: Context) throws {
        totalCount = try node.extract("total_count")
        
        /// FIX ME SENPAI
    }
    
    public func makeNode() throws -> Node {
        return try Node(node: [
            "total_count": totalCount
        ])
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}

/** 
 Represents a file ready to be downloaded.  The file can be downloaded via the link https://api.telegram.org/file/bot<token>/<file_path>.  It is guaranteed that the link will be valid for at least one hour.  When the link expires, a new one can be requested by calling getFile.
 */
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
        fileID = try node.extract("file_id")
        fileSize = try node.extract("file_size")
        filePath = try node.extract("file_path")
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


/*
This object represents an incoming callback query from a callback button in an inline keyboard. 
 
If the button that originated the query was attached to a message sent by the bot, the field message will be present. If the button was attached to a message sent via the bot (in inline mode), the field inline_message_id will be present. Exactly one of the fields data or game_short_name will be present.
 */

public class CallbackQuery: NodeConvertible, JSONConvertible {
    public var id: String // Unique identifier for the query.
    public var from: User // The sender of the query.
    public var message: Message? // message with the callback button that originated from the query.  Won't be available if it's too old.
    public var inlineMessageID: String? // Identifier of the message sent via the bot in inline mode that originated the query.
    public var chatInstance: String? // Global identifier, uniquely corresponding to the chat to which the message with the callback button was sent.  Useful for high scores in games.
    public var data: String? // Data associated with the callback button.  Be aware that a bad client can send arbitrary data here.
    public var gameShortName: String? // Short name of a Game to be returned, serves as the unique identifier for the game.
    
    
    public init(id: String, from: User) {
        self.id = id
        self.from = from
    }
    
    // NodeRepresentable conforming methods
    public required init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        
        guard let subFrom = node["from"] else { throw TGTypeError.ExtractFailed }
        self.from = try .init(node: subFrom, in: context) as User
    
        if let subMessage = node["message"] {
            self.message = try .init(node: subMessage, in: context) as Message }
        
        inlineMessageID = try node.extract("inline_message_id")
        chatInstance = try node.extract("chat_instance")
        data = try node.extract("data")
        gameShortName = try node.extract("game_short_name")
    }
    
    public func makeNode() throws -> Node {
        var keys: [String:NodeRepresentable] = [
            "id": id,
            "from": from
            ]
        
        if message != nil { keys["message"] = message }
        if inlineMessageID != nil { keys["inline_message_id"] = inlineMessageID }
        if chatInstance != nil { keys["chat_instance"] = chatInstance }
        if data != nil { keys["data"] = data }
        if gameShortName != nil { keys["game_short_name"] = gameShortName }
        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}


// Status of a chat member, in a group.
public enum ChatMemberStatus: String {
    case creator = "creator", administrator, member, left, kicked
}

// Contains information about one member of the chat.
public class ChatMember: NodeConvertible, JSONConvertible {
    public var user: User
    public var status: ChatMemberStatus // The member's status in the chat. Can be “creator”, “administrator”, “member”, “left” or “kicked”.
    
    public init(user: User, status: ChatMemberStatus) {
        self.user = user
        self.status = status
    }
    
    
    // NodeRepresentable conforming methods
    public required init(node: Node, in context: Context) throws {
        user = try node.extract("user")
        let text = try node.extract("status").string
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
    
    public func makeNode() throws -> Node {
        return try Node(node: [
            "user": user,
            "status": status.rawValue
        ])
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}

// Contains information about why a request was unsuccessfull.
public class ResponseParameters: NodeConvertible, JSONConvertible {
    public var migrateToChatID: Int? // ???
    public var retryAfter: Int? // ???
    
    public init(retryAfter: Int) {
        self.retryAfter = retryAfter
    }
    
    // NodeRepresentable conforming methods
    public required init(node: Node, in context: Context) throws {
        migrateToChatID = try node.extract("migrate_to_chat_id")
        retryAfter = try node.extract("retry_after")
    }
    
    public func makeNode() throws -> Node {
        var keys: [String:NodeRepresentable] = [:]
        
        if migrateToChatID != nil { keys["migrate_to_chat_id"] = migrateToChatID }
        if retryAfter != nil { keys["retry_after"] = retryAfter }
        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}


