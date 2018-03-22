//
//  FileDownload.swift
//  Pelican
//
//  Created by Ido Constantine on 22/03/2018.
//

import Foundation

/**
Represents a file ready to be downloaded.  Use the API method `getFile` to request a FileDownload type.
*/
public struct FileDownload: Codable {
	
	/// Unique identifier for the file.
	var fileID: String
	
	/// The file size, if known
	var fileSize: Int?
	
	/// The path that can be used to download the file, using https://api.telegram.org/file/bot<token>/<file_path>.
	var filePath: String?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case fileID = "file_id"
		case fileSize = "file_size"
		case filePath = "file_path"
	}
}
