//
//  FileLink.swift
//  Pelican
//
//  Created by Ido Constantine on 21/08/2017.
//

import Foundation

/** Defines a link to a file, either located in /Public or as a HTTP link to a file.
*/
public struct FileLink {
	public enum UploadLocation {
		case path(String)
		case http(String)
	}
	
	public var name: String = ""
	public var location: UploadLocation
	public var type: FileType
	public var id: String {
		switch location {
		case .path(let path):
			return path
		case .http(let http):
			return http
		}
	}
	
	/**
	Initialises the FileLink using a path to a local resource.  The path must be local and defined from /Public.
	
	eg. ```karaoke/jack1.png```
	*/
	public init(withPath path: String, type: FileType) {
		self.location = .path(path)
		self.type = type
		
		var pathChunks = path.components(separatedBy: "/")
		self.name = pathChunks.removeLast()
	}
	
	/**
	Initialises the FileLink using a path to an external resource, as an HTTP link.
	
	- warning: Pelican currently doesn't support HTTP uploading, please don't use it.
	*/
	public init(withHTTP http: String, type: FileType) {
		self.location = .http(http)
		self.type = type
	}
}
