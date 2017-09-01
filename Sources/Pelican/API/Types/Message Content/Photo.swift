//
//  Photo.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider


/**
Represents one size of a photo sent from a message, a photo you want to send to a chat, or a file/sticker.
*/
final public class Photo: TelegramType, MessageFile {
	
	// STORAGE AND IDENTIFIERS
	public var storage = Storage()
	public var contentType: String = "photo" // MessageType conforming variable for Message class filtering.
	public var method: String = "sendPhoto" // SendType conforming variable for use when sent
	
	// FILE SOURCE
	public var fileID: String?
	public var url: String?
	
	// PARAMETERS
	public var width: Int?
	public var height: Int?
	public var fileSize: Int?
	
	
	public init(fileID: String, width: Int? = nil, height: Int? = nil, fileSize: Int? = nil) {
		self.fileID = fileID
		self.width = width
		self.height = height
		self.fileSize = fileSize
	}
	
	public init?(url: String, width: Int? = nil, height: Int? = nil, fileSize: Int? = nil) {
		
		if url.checkURLValidity(acceptedExtensions: ["png", "jpg"]) == false { return nil }
		
		self.url = url
		self.width = width
		self.height = height
		self.fileSize = fileSize
	}
	
	public func getQuery() -> [String : NodeConvertible] {
		let keys: [String:NodeConvertible] = [
			"photo": fileID]
		
		return keys
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
