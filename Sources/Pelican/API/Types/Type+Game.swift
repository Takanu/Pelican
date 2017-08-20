
import Foundation
import Vapor
import FluentProvider

/** This object represents a game. Use BotFather to create and edit games, their short names will act as unique identifiers. 
 */
final public class Game: Model {
	public var storage = Storage()
	
  public var title: String                 // Title of the game
  public var description: String           // Description of the game
  public var photo: [PhotoSize]            // Photo that will be displayed in the game message in chats.
  public var text: String?                 // Brief description of the game as well as provide space for high scores.
  public var textEntries: [MessageEntity]? // Special entities that appear in text, such as usernames.
  public var animation: String?            // Animation type that will be displayed in the game message in chats.  Upload via BotFather
  
  
  // NodeRepresentable conforming methods
  required public init(row: Row) throws {
    title = try row.get("title")
    description = try row.get("description")
    photo = try row.get("photo")
    text = try row.get("text")
    textEntries = try row.get("text_entities")
    animation = try row.get("animation")
  }
  
	// RowRepresentable conforming methods
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("title", title)
		try row.set("description", description)
		try row.set("photo", photo)
		try row.set("text", text)
		try row.set("text_entities", textEntries)
		try row.set("animation", animation)
		
		return row
	}
}


/** You can provide an animation for your game so that it looks stylish in chats (check out Lumberjack for an example). This object represents an animation file to be displayed in the message containing a game. 
 */
final public class Animation: Model {
	public var storage = Storage()
	
  public var fileID: String      // Unique file identifier.
  public var thumb: PhotoSize?   // Animation thumbnail as defined by the sender.
  public var fileName: String?   // Original animation filename as defined by the sender.
  public var mimeType: String?   // MIME type of the file as defined by sender.
  public var fileSize: Int?      // File size.
  
  
  // NodeRepresentable conforming methods
  required public init(row: Row) throws {
    fileID = try row.get("file_id")
    thumb = try row.get("thumb")
    fileName = try row.get("file_name")
    mimeType = try row.get("mime_type")
    fileSize = try row.get("file_size")
  }
  
	// RowRepresentable conforming methods
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


/** This object represents one row of the high scores table for a game.
*/
final public class GameHighScore: Model {
	public var storage = Storage()
	
  var position: Int     // Position in the high score table for the game
  var user: User        // User who made the score entry
  var score: Int        // The score the user set
  
  
  // NodeRepresentable conforming methods
  required public init(row: Row) throws {
    position = try row.get("position")
    user = try row.get("user")
    score = try row.get("score")
  }
  
	// RowRepresentable conforming methods
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("position", position)
		try row.set("user", user)
		try row.set("score", score)
		
		return row
	}
}
