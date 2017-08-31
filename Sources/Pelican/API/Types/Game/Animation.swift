//
//  Animation.swift
//  Pelican
//
//  Created by Ido Constantine on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

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
