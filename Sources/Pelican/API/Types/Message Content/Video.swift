//
//  Video.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/**
Represents a video file.  Go figure.
*/
public struct Video: TelegramType, MessageFile {
	
	// STORAGE AND IDENTIFIERS
	public var contentType: String = "video"
	public var method: String = "sendVideo"
	
	// FILE SOURCE
	public var fileID: String?
	public var url: String?
	
	// PARAMETERS
	/// Width of the video in pixels.
	public var width: Int?
	
	/// Height of the video in pixels.
	public var height: Int?
	
	/// Duration of the video in seconds.
	public var duration: Int?
	
	/// A thumbnail displayed for the video before it plays.
	public var thumb: Photo?
	
	/// The mime type of the video.
	public var mimeType: String?
	
	/// The file size of the video
	public var fileSize: Int?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case fileID = "file_id"
		case url
		
		case width
		case height
		case duration
		case thumb
		case mimeType = "mime_type"
		case fileSize = "file_size"
	}
	
	
	public init(fileID: String,
							width: Int? = nil,
							height: Int? = nil,
							duration: Int? = nil,
							thumb: Photo? = nil,
							mimeType: String? = nil,
							fileSize: Int? = nil) {
		
		self.fileID = fileID
		self.width = width
		self.height = height
		self.duration = duration
		self.thumb = thumb
		self.mimeType = mimeType
		self.fileSize = fileSize
	}
	
	
	public init?(url: String,
							 width: Int? = nil,
							 height: Int? = nil,
							 duration: Int? = nil,
							 thumb: Photo? = nil,
							 mimeType: String? = nil,
							 fileSize: Int? = nil) {
		
		if url.checkURLValidity(acceptedExtensions: ["mp4"]) == false { return nil }
		
		self.url = url
		self.width = width
		self.height = height
		self.duration = duration
		self.thumb = thumb
		self.mimeType = mimeType
		self.fileSize = fileSize
	}
	
	
	// SendType conforming methods to send itself to Telegram under the provided method.
	public func getQuery() -> [String: Codable] {
		var keys: [String: Codable] = [
			"video": fileID]
		
		if duration != 0 { keys["duration"] = duration }
		if width != 0 { keys["width"] = width }
		if height != 0 { keys["height"] = height }
		
		return keys
	}
}
