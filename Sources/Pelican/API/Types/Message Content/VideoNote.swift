//
//  VideoNote.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

/**
Represents a VideoNote type, introduced in Telegram 4.0.
*/
final public class VideoNote: TelegramType, MessageContent, MessageFile {
	
	// STORAGE AND IDENTIFIERS
	public var storage = Storage()
	public var contentType: String = "video_note" // MessageType conforming variable for Message class filtering.
	public var method: String = "sendVideoNote" // SendType conforming variable for use when sent
	
	// FILE SOURCE
	public var fileID: String?
	public var url: String?
	
	// PARAMETERS
	public var length: Int?
	public var duration: Int?
	public var thumb: Photo?
	public var fileSize: Int?
	
	
	public init(fileID: String, length: Int? = nil, duration: Int? = nil, thumb: Photo? = nil, fileSize: Int? = nil) {
		self.fileID = fileID
		self.length = length
		self.duration = duration
		self.thumb = thumb
		self.fileSize = fileSize
	}
	
	public init?(url: String, length: Int? = nil, duration: Int? = nil, thumb: Photo? = nil, fileSize: Int? = nil) {
		
		if url.checkURLValidity(acceptedExtensions: ["mp4"]) == false { return nil }
		
		self.url = url
		self.length = length
		self.duration = duration
		self.thumb = thumb
		self.fileSize = fileSize
	}
	
	
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
		if let thumbRow = row["thumb"] {
			self.thumb = try .init(row: Row(thumbRow)) as Photo
		}
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
