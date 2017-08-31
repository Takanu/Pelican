//
//  Document.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

/**
Represents a generic file type, typically not covered by other Telegram file types (like Audio, Voice or Photo).
*/
final public class Document: TelegramType, MessageFile {
	
	// STORAGE AND IDENTIFIERS
	public var storage = Storage()
	public var contentType: String = "document"
	public var method: String = "/sendDocument" 
	
	// FILE SOURCE
	public var fileID: String?
	public var url: String?
	
	// PARAMETERS
	/// Document thumbnail.
	public var thumb: PhotoSize?
	/// Original filename.
	public var fileName: String?
	/// MIME type of the file.
	public var mimeType: String?
	/// File size.
	public var fileSize: String?
	
	
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
		if let thumbRow = row["thumb"] {
			self.thumb = try .init(row: Row(thumbRow)) as PhotoSize
		}
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
