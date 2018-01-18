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
	public var contentType: String = "photo"
	public var method: String = "sendPhoto"
	
	// FILE SOURCE
	public var fileID: String?
	public var url: String?
	
	// PARAMETERS
	/// The width of the photo in pixels.
	public var width: Int?
	
	/// Height of the photo in pixels.
	public var height: Int?
	
	/// The file size of the photo.
	public var fileSize: Int?
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case fileID = "file_id"
		case url
		
		case width
		case height
		case fileSize = "file_size"
	}
	
	
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
}
