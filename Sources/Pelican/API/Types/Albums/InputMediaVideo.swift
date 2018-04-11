//
//  InputMediaVideo.swift
//  Pelican
//
//  Created by Takanu Kyriako on 21/12/2017.
//

import Foundation

/**
Represents a video to be sent in the context of an album.
*/
struct InputMediaVideo: InputMedia {
	
	// PROTOCOL INHERITANCE
	public var type = "video"
	public var media: String
	public var caption: String?
	
	// DETAILS
	/// The width of the video in pixels
	public var width: Int?
	
	/// The height of the video in pixels.
	public var height: Int?
	
	/// The duration of the video in seconds.
	public var duration: Int?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case type
		case media
		case caption
		
		case width
		case height
		case duration
	}
	
	public init(mediaLink media: String,
							caption: String?,
							width: Int? = nil,
							height: Int? = nil,
							duration: Int? = nil) {
		
		self.media = media
		self.caption = caption
	}
}
