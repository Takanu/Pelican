//
//  Audio.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/**
Represents an audio file to be treated as music by the Telegram clients.
*/
public struct Audio: TelegramType, MessageFile {
	
	// STORAGE AND IDENTIFIERS
	/// The content type it represents, used by Telegram to interpret what is being sent.
	public var contentType: String = "audio"
	
	/// The method that will be used to send this content type.
	public var method: String = "sendAudio"
	
	// FILE SOURCE
	public var fileID: String?
	public var url: String?
	
	// PARAMETERS
	/// Duration of the audio in seconds as defined by the sender.
	public var duration: Int?
	
	/// Performer of the audio as defined by the sender or by audio tags
	public var performer: String?
	
	/// Title of the audio as defined by the sender or by audio tags.
	public var title: String?
	
	/// MIME type of the file as defined by the sender.
	public var mimeType: String?
	
	/// File size of the audio file.  Only specify if you reeeeally have to.
	public var fileSize: Int?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case fileID = "file_id"
		case url
		
		case duration
		case performer
		case title
		case mimeType = "mime_type"
		case fileSize = "file_size"
	}
	
	/**
	Initialises an Audio object based on a Telegram File ID and any optional parameters.
	*/
	public init(fileID: String,
							duration: Int = 0,
							performer: String? = nil,
							title: String? = nil,
							mimeType: String? = nil,
							fileSize: Int? = 0) {
		
		self.fileID = fileID
		self.duration = duration
		self.performer = performer
		self.title = title
		self.mimeType = mimeType
		self.fileSize = fileSize
	}
	
	/**
	Initialises an Audio object based on a URL and any optional parameters.  The URL can be defined either as a local source relative to the Public/ folder
	of your app (eg. `karaoke/jack-1.png`) or as a remote source using an HTTP link.
	
	- warning: The URL must link to a MP3 formatted file, this is the only file type that can be sent using this type.
	*/
	public init?(url: String,
							 duration: Int = 0,
							 performer: String? = nil,
							 title: String? = nil,
							 mimeType: String? = nil,
							 fileSize: Int? = 0) {
		
		if url.checkURLValidity(acceptedExtensions: ["mp3"]) == false { return nil }
		
		self.url = url
		self.duration = duration
		self.performer = performer
		self.title = title
		self.mimeType = mimeType
		self.fileSize = fileSize
	}
	
	// SendType conforming methods
	public func getQuery() -> [String: Codable] {
		var keys: [String: Codable] = [
			"audio": fileID]
		
		if duration != 0 { keys["duration"] = duration }
		if performer != nil { keys["performer"] = performer }
		if title != nil { keys["title"] = title }
		
		return keys
	}
	
}
