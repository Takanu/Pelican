//
//  InputMedia.swift
//  Pelican
//
//  Created by Ido Constantine on 21/12/2017.
//

import Foundation

/**
Represents a type of media to be sent in the format of an album.
*/
public protocol InputMedia: Codable {
	
	/// The content type that this media represents.
	var type: String { get }
	
	/// The file to send.  Pass a file_id to send a file that exists on the Telegram servers (recommended), pass an HTTP URL for Telegram to get a file from the Internet, or pass "attach://<file_attach_name>" to upload a new one using multipart/form-data under <file_attach_name> name.
	var media: String { get set }
	
	/// A caption for the document to be sent, 200 characters maximum.
	var caption: String? { get set }
}
