//
//  Voice.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

final public class Voice: TelegramType, MessageFile {
	
	// STORAGE AND IDENTIFIERS
	public var storage = Storage()
	public var contentType: String = "voice" // MessageType conforming variable for Message class filtering.
	public var method: String = "/sendVoice" // SendType conforming variable for use when sent
	
	// FILE SOURCE
	public var fileID: String?
	public var url: String?
	
	// PARAMETERS
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
