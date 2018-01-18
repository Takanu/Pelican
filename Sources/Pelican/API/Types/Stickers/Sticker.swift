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
	public var contentType: String = "sticker"
	public var method: String = "sendSticker"
	
	// FILE SOURCE
	public var fileID: String?
	public var url: String?
	
	// PARAMETERS
	/// The width of the sticker in pixels.
	public var width: Int?
	
	/// The height of the sticker in pixels.
	public var height: Int?
	
	/// Sticker thumbnail in .webp or .jpg format.
	public var thumb: Photo?
	
	/// A series of emoji associated with the sticker.
	public var emoji: String?
	
	/// The file size of the sticker.
	public var fileSize: Int?
	
	/// The name of the sticker set that this sticker belongs to.
	public var stickerSetName: String?
	
	/// For mask stickers, the position where the mask should be placed.
	public var maskPosition: MaskPosition?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case fileID = "file_id"
		case url
		
		case width
		case height
		case thumb
		case emoji
		case fileSize = "file_size"
		case stickerSetName = "set_name"
		case maskPosition = "mask_position"
	}
	
	public init(fileID: String, width: Int? = nil, height: Int? = nil, thumb: Photo? = nil, emoji: String? = nil, fileSize: Int? = nil) {
		self.fileID = fileID
		self.width = width
		self.height = height
		self.thumb = thumb
		self.emoji = emoji
		self.fileSize = fileSize
	}
	
	public init?(url: String, width: Int? = nil, height: Int? = nil, thumb: Photo? = nil, emoji: String? = nil, fileSize: Int? = nil) {
		
		if url.checkURLValidity(acceptedExtensions: ["webp", "jpg"]) == false { return nil }
		
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
}
