//
//  Sticker.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

/**
Represents a Telegram sticker.
*/
final public class Sticker: TelegramType, MessageFile {
	
	// STORAGE AND IDENTIFIERS
	public var storage = Storage()
	public var contentType: String = "sticker"
	public var method: String = "sendSticker"
	
	// FILE SOURCE
	public var fileID: String?
	public var url: String?
	
	// PARAMETERS
	public var width: Int?
	public var height: Int?
	public var thumb: Photo? // Sticker thumbnail in .webp or .jpg format.
	public var emoji: String? // Emoji associated with the sticker.
	public var fileSize: Int?
	
	public init(fileID: String, width: Int? = nil, height: Int? = nil, thumb: Photo? = nil, emoji: String? = nil, fileSize: Int? = nil) {
		self.fileID = fileID
		self.width = width
		self.height = height
		self.thumb = thumb
		self.emoji = emoji
		self.fileSize = fileSize
	}
	
	public init?(url: String, width: Int? = nil, height: Int? = nil, thumb: Photo? = nil, emoji: String? = nil, fileSize: Int? = nil) {
		
		if url.checkURLValidity(acceptedExtensions: ["png", "jpg"]) == false { return nil }
		
		self.url = url
		self.width = width
		self.height = height
		self.thumb = thumb
		self.emoji = emoji
		self.fileSize = fileSize
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
		if let thumbRow = row["thumb"] {
			self.thumb = try .init(row: Row(thumbRow)) as Photo
		}
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
