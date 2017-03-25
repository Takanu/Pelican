
import Foundation
import Vapor

/* This object represents a game. Use BotFather to create and edit games, their short names will act as unique identifiers. */
public class Game: NodeConvertible, JSONConvertible {
    var title: String // Title of the game
    var description: String // Description of the game
    var photo: [PhotoSize] // Photo that will be displayed in the game message in chats.
    var text: String? // Brief description of the game as well as provide space for high scores.
    var textEntries: [MessageEntity]? // Special entities that appear in text, such as usernames.
    var animation: String? // Animation type that will be displayed in the game message in chats.  Upload via BotFather
    
    // NodeRepresentable conforming methods
    required public init(node: Node, in context: Context) throws {
        title = try node.extract("title")
        description = try node.extract("description")
        photo = try node.extract("photo")
        text = try node.extract("text")
        textEntries = try node.extract("text_entities")
        animation = try node.extract("animation")
    }
    
    public func makeNode() throws -> Node {
        let photoNode = try! photo.makeNode()
        
        var keys: [String:NodeRepresentable] = [
            "title": title,
            "description": description,
            "photo": photoNode
        ]
        
        if text != nil { keys["text"] = text }
        if textEntries != nil { keys["text_entities"] = try! textEntries!.makeNode() }
        if animation != nil { keys["animation"] = animation }
        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}


/* You can provide an animation for your game so that it looks stylish in chats (check out Lumberjack for an example). This object represents an animation file to be displayed in the message containing a game. */
public class Animation: NodeConvertible, JSONConvertible {
    var fileID: String // Unique file identifier.
    var thumb: PhotoSize? // Animation thumbnail as defined by the sender.
    var fileName: String? // Original animation filename as defined by the sender.
    var mimeType: String? // MIME type of the file as defined by sender.
    var fileSize: Int? // File size.
    
    // NodeRepresentable conforming methods
    required public init(node: Node, in context: Context) throws {
        fileID = try node.extract("file_id")
        thumb = try node.extract("thumb")
        fileName = try node.extract("file_name")
        mimeType = try node.extract("mime_type")
        fileSize = try node.extract("file_size")
    }
    
    public func makeNode() throws -> Node {
        var keys: [String:NodeRepresentable] = [
            "file_id": fileID
        ]
        
        if thumb != nil { keys["thumb"] = thumb }
        if fileName != nil { keys["file_name"] = fileSize }
        if mimeType != nil { keys["mime_type"] = mimeType }
        if fileSize != nil { keys["file_size"] = fileSize }
        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}

/* This object represents one row of the high scores table for a game. */
public class GameHighScore: NodeConvertible, JSONConvertible {
    var position: Int // Position in the high score table for the game
    var user: User // User who made the score entry
    var score: Int // The score the user set
    
    // NodeRepresentable conforming methods
    required public init(node: Node, in context: Context) throws {
        position = try node.extract("position")
        user = try node.extract("user")
        score = try node.extract("score")
    }
    
    public func makeNode() throws -> Node {
        let keys: [String:NodeRepresentable] = [
            "position": position,
            "user": user,
            "score": score
        ]
        
        return try Node(node: keys)
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}
