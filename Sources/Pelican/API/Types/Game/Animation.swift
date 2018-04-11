//
//  Animation.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/** 
This object represents an animation file to be displayed in a Telegram message containing a game, used for additional visual flair and to better preview what your game is to 
*/
public struct Animation: Codable {
	
	/// A unique file identifier for the animation.
	public var fileID: String
	
	/// Animation thumbnail as defined by the sender.
	public var thumb: Photo?
	
	/// Original animation filename as defined by the sender.
	public var fileName: String?
	
	/// MIME type of the file as defined by sender.
	public var mimeType: String?
	
	/// File size.
	public var fileSize: Int?
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case fileID = "file_id"
		case thumb
		case fileName = "file_name"
		case mimeType = "mime_type"
		case fileSize = "file_size"
	}
	
	
	public init(fileID: String,
							thumb: Photo? = nil,
							fileName: String? = nil,
							mimeType: String? = nil,
							fileSize: Int? = nil) {
		
		self.fileID = fileID
		self.thumb = thumb
		self.fileName = fileName
		self.mimeType = mimeType
		self.fileSize = fileSize
	}
	
}
