
import Foundation




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



// Contains information about why a request was unsuccessful.
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


