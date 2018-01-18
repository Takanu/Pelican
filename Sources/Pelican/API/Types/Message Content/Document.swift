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
	public var contentType: String = "document"
	public var method: String = "sendDocument" 
	
	// FILE SOURCE
	public var fileID: String?
	public var url: String?
	
	// PARAMETERS
	/// Document thumbnail.
	public var thumb: Photo?
	
	/// Original filename.
	public var fileName: String?
	
	/// MIME type of the file.
	public var mimeType: String?
	
	/// File size.
	public var fileSize: String?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case fileID = "file_id"
		case url
		
		case thumb = "thumb"
		case fileName = "file_name"
		case mimeType = "mime_type"
		case fileSize = "file_size"
	}
	
	
	public init(fileID: String, thumb: Photo? = nil, fileName: String? = nil, mimeType: String? = nil, fileSize: String? = nil) {
		self.fileID = fileID
		self.thumb = thumb
		self.fileName = fileName
		self.mimeType = mimeType
		self.fileSize = fileSize
	}
	
	public init?(url: String, thumb: Photo? = nil, fileName: String? = nil, mimeType: String? = nil, fileSize: String? = nil) {
		
		if url.checkURLValidity(acceptedExtensions: []) == false { return nil }
		
		self.url = url
		self.thumb = thumb
		self.fileName = fileName
		self.mimeType = mimeType
		self.fileSize = fileSize
	}
	
	// SendType conforming methods
	public func getQuery() -> [String:NodeConvertible] {
		let keys: [String:NodeConvertible] = [
			"document": fileID]
		
		return keys
	}
	
}
