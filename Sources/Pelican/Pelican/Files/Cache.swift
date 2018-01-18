//
//  CacheManager.swift
//  Pelican
//
//  Created by Takanu Kyriako on 21/08/2017.
//

import Foundation
import Vapor
import FluentProvider
import FormData
import Multipart
import HTTP

/** Manages a database of currently active file links for re-use, as well as asynchronously uploads content
that doesn't have a link.

The database updates itself when a FileLink class is sent using the bot or a session, enabling content to
be re-used and saving resources in the process.
*/
public class CacheManager {
	private var bundle: Bundle?
	
	// CACHE
	var cache: [CacheFile] = []
	
	var cacheLength: Int = 0        // The length of time a file is cached on Telegram's servers before
	// it needs re-uploading. 0 = No timer.
	
	init() { }
	
	func setBundlePath(_ path: String) throws {
		self.bundle = Bundle(path: path)
		if self.bundle == nil { throw CacheError.BadBundle }
	}
	
	/** Used to keep cache types separate, to make cache searching less intensive?  (idk).
	This should be replaced with one stack that can then filter using generics.
	*/
	func getCache() -> [CacheFile] {
		return cache
	}
	
	
	
	// I need to work out a way to compare and reliably keep an up-to-date cache system, for now it just helps get file data.
	/*
	
	/**
	Adds a successfully uploaded MessageFile resource to the cache list.
	*/
	func add(file: MessageFile, message: Message) throws {
		
		guard let cacheFile = CacheFile(file: file) else {
			return
		}
	}
	
	/** Tries to find whether an uploaded version of that file exists in the cache.
	Returns the object if true, or nothing if false.
	*/
	func find(file: MessageFile, bot: Pelican) -> MessageContent? {
		let cache = getCache(type: upload.type)
		for item in cache {
			
			// If the item hashes dont match, keep cycling
			if item.uploadData.id != upload.id { continue }
			
			// If they do and the upload timer has expired, return no ID and remove it from the cache
			if bot.globalTimer > item.uploadTime + cacheLength && cacheLength != 0 { return nil }
			
			// Otherwise, return the ID
			return item.getFile
		}
		return nil
	}
	*/
	
	/** Attempts to retrieve the raw data for the requested resource.
	- parameter upload: The file you wish to get raw data for.
	*/
	func fetchFile(path: String) throws -> Bytes? {
		
		if path.contains("://") {
			
		}
	
			
		else {
			if bundle == nil {
				PLog.error(CacheError.BadBundle.rawValue)
				return nil
			}
			
			// Get the combined name and extension
			var pathChunks = path.components(separatedBy: "/")
			let nameAndExt = pathChunks.removeLast()
			
			// Get the raw path
			let path = path.replacingOccurrences(of: nameAndExt, with: "")
			let name = nameAndExt.components(separatedBy: ".").first!
			var ext = nameAndExt.components(separatedBy: ".").last!
			ext = "." + ext
			
			// Try getting the URL
			guard let url = bundle!.url(forResource: name, withExtension: ext, subdirectory: path)
				else {
					PLog.error(CacheError.LocalNotFound.rawValue)
					return nil
			}
			
			// Try getting the bytes
			do {
				let image = try Data(contentsOf: url)
				let bytes = image.makeBytes()
				return bytes
				
			} catch {
				PLog.error(CacheError.LocalNotFound.rawValue)
				return nil
			}
		}
		
		return nil
	}
	
	/**
	Attempts to retrieve data on the given MessageFile that would allow it to be send in a Telegram Request.

	- returns: A form data entry with all the information necessary to send or re-link the file in a message, or nil if this was not possible.
	*/
	func getFormEntry(forFile file: MessageFile) throws -> [String:FormData.Field]? {
		
		if file.fileID != nil {
			return [file.contentType: Field(name: file.contentType, filename: file.fileID!, part: Part(headers: [HeaderKey.contentType:"text/html"], body: file.fileID!.bytes) )]
		}
		
		else if file.url != nil {
			
			var bytes: Bytes?
			do {
				bytes = try fetchFile(path: file.url!)
			} catch {
				throw error
			}
			
			if bytes == nil {
				throw CacheError.NoBytes
			}
			
			let fileName = file.url!.components(separatedBy: "/").last!
			//let ext = file.url!.components(separatedBy: ".").last!
				
			return [file.contentType: Field(name: file.contentType, filename: fileName, part: Part(headers: [HeaderKey.contentType:"multipart/form-data"], body: bytes!) )]
		}
		
		throw CacheFormError.LinkNotFound
	}
}
