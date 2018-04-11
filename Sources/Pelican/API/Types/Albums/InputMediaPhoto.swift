//
//  InputMediaPhoto.swift
//  Pelican
//
//  Created by Takanu Kyriako on 21/12/2017.
//

import Foundation

/**
Represents a photo to be sent in the context of an album.
*/
struct InputMediaPhoto: InputMedia {
	
	// PROTOCOL INHERITANCE
	public var type = "photo"
	public var media: String
	public var caption: String?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case type
		case media
		case caption
	}
	
	public init(mediaLink media: String, caption: String?) {
		self.media = media
		self.caption = caption
	}
}
