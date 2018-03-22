//
//  Voice.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/**
Represents a Voice type, which will appear as if it was a user-recorded voice message if sent.
*/
final public class Voice: TelegramType, MessageFile {
	
	// STORAGE AND IDENTIFIERS
	public var contentType: String = "voice"
	public var method: String = "sendVoice"
	
	// FILE SOURCE
	public var fileID: String?
	public var url: String?
	
	// PARAMETERS
	/// The duration of the voice note, in seconds.
	public var duration: Int?
	
	/// The mime type of the voice file.
	public var mimeType: String?
	
	/// The file size.
	public var fileSize: Int?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case fileID = "file_id"
		case url
		
		case duration
		case mimeType = "mime_type"
		case fileSize = "file_size"
	}
	
	public init(fileID: String, duration: Int? = nil, mimeType: String? = nil, fileSize: Int? = nil) {
		self.fileID = fileID
		self.duration = duration
		self.mimeType = mimeType
		self.fileSize = fileSize
	}
	
	public init?(url: String, duration: Int? = nil, mimeType: String? = nil, fileSize: Int? = nil) {
		
		if url.checkURLValidity(acceptedExtensions: ["ogg"]) == false { return nil }
		
		self.url = url
		self.duration = duration
		self.mimeType = mimeType
		self.fileSize = fileSize
	}
	
	// SendType conforming methods to send itself to Telegram under the provided method.
	public func getQuery() -> [String: Codable] {
		var keys: [String: Codable] = [
			"voice": fileID]
		
		if duration != 0 { keys["duration"] = duration }
		
		return keys
	}
}
