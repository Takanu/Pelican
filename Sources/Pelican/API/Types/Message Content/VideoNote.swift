//
//  VideoNote.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/**
Represents a VideoNote type, introduced in Telegram 4.0.
*/
final public class VideoNote: TelegramType, MessageContent, MessageFile {
	
	// STORAGE AND IDENTIFIERS
	public var contentType: String = "video_note"
	public var method: String = "sendVideoNote"
	
	// FILE SOURCE
	public var fileID: String?
	public var url: String?
	
	// PARAMETERS
	/// Width and height of the video in pixels.
	public var length: Int?
	
	/// Duration of the video in seconds.
	public var duration: Int?
	
	/// A thumbnail displayed for the video before it plays.
	public var thumb: Photo?
	
	/// The file size of the video
	public var fileSize: Int?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case fileID = "file_id"
		case url
		
		case length
		case duration
		case thumb
		case fileSize = "file_size"
	}
	
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
}
