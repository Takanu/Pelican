//
//  Video.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

final public class Video: TelegramType, MessageFile {
	
	// STORAGE AND IDENTIFIERS
	public var storage = Storage()
	public var contentType: String = "video" // MessageType conforming variable for Message class filtering.
	public var method: String = "/sendVideo" // SendType conforming variable for use when sent
	
	// FILE SOURCE
	public var fileID: String?
	public var url: String?
	
	// PARAMETERS
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
		if let thumbRow = row["thumb"] {
			self.thumb = try .init(row: Row(thumbRow)) as PhotoSize
		}
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
