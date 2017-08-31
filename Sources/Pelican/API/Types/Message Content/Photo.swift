//
//  Photo.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

// This doesn't belong to any Telegram type, just a convenience class for enclosing PhotoSize

final public class Photo: TelegramType, MessageContent {
	public var storage = Storage()
	public var contentType: String = "photo" // MessageType conforming variable for Message class filtering.
	public var method: String = "/sendPhoto" // SendType conforming variable for use when sent
	public var photos: [PhotoSize] = []
	
	public init(photos: [PhotoSize]) {
		self.photos = photos
	}
	
	// SendType conforming methods
	public func getQuery() -> [String:NodeConvertible] {
		let keys: [String:NodeConvertible] = [
			"photo": photos.map( { $0.fileID	})]
		
		return keys
	}
	
	// NodeRepresentable conforming methods
	public required init(row: Row) throws {
		if let photoRow = row["photos"] {
			self.photos = try photoRow.array?.map( { try PhotoSize(row: $0) } ) ?? []
		}
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("photos", photos)
		
		return row
	}
}



/// THERES A PROBLEM HERE
final public class PhotoSize: TelegramType {
	public var storage = Storage()
	
	public var fileID: String?
	public var url: String?
	
	public var width: Int // Photo width
	public var height: Int // Photo height
	public var fileSize: Int? // File size
	
	
	public init(fileID: String, width: Int, height: Int) {
		self.fileID = fileID
		self.width = width
		self.height = height
	}
	
	// NodeRepresentable conforming methods
	public required init(row: Row) throws {
		fileID = try row.get("file_id")
		width = try row.get("width")
		height = try row.get("height")
		fileSize = try row.get("file_size")
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("file_id", fileID)
		try row.set("width", width)
		try row.set("height", height)
		try row.set("file_size", fileSize)
		
		return row
	}
}
