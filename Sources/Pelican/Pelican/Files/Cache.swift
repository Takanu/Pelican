//
//  CacheManager.swift
//  Pelican
//
//  Created by Ido Constantine on 21/08/2017.
//

import Foundation
import Vapor

/** Manages a database of currently active file links for re-use, as well as asynchronously uploads content
that doesn't have a link.

The database updates itself when a FileLink class is sent using the bot or a session, enabling content to
be re-used and saving resources in the process.
*/
public class CacheManager {
	private var bundle: Bundle?
	
	// Caches
	var audios: [CacheFile] = []
	var photos: [CacheFile] = []
	var documents: [CacheFile] = []
	var stickers: [CacheFile] = []
	var videos: [CacheFile] = []
	var voices: [CacheFile] = []
	
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
	internal func getCache(type: FileType) -> [CacheFile] {
		switch type {
		case .audio:
			return audios
		case .photo:
			return photos
		case .document:
			return documents
		case .sticker:
			return stickers
		case .video:
			return videos
		case .voice:
			return voices
		}
	}
	
	internal func setCache(_ cache: [CacheFile], type: FileType) {
		switch type {
		case .audio:
			audios = cache; return
		case .photo:
			photos = cache; return
		case .document:
			documents = cache; return
		case .sticker:
			stickers = cache; return
		case .video:
			videos = cache; return
		case .voice:
			voices = cache; return
		}
	}
	
	/** Adds the cached resource to the list given a successful response message.
	*/
	func add(upload: FileLink, message: Message) -> Bool {
		let file = try! CacheFile(upload: upload, file: message, time: 0)
		var cache: [CacheFile] = getCache(type: file.getType)
		
		if cache.contains(where: { $0.uploadData.id == upload.id }) == false {
			cache.append(file)
			setCache(cache, type: file.getType)
			return true
		}
		
		return false
	}
	
	/** Tries to find whether an uploaded version of that file exists in the cache.
	Returns the object if true, or nothing if false.
	*/
	func find(upload: FileLink, bot: Pelican) -> SendType? {
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
	
	/** Attempts to retrieve the raw data for the requested resource.
	- parameter upload: The file you wish to get raw data for.
	*/
	func get(upload: FileLink) -> Bytes? {
		
		switch upload.location {
			
		case .path(path: let fullPath):
			if bundle == nil {
				print(CacheError.BadBundle.rawValue)
				return nil
			}
			
			// Get the combined name and extension
			var pathChunks = fullPath.components(separatedBy: "/")
			let nameAndExt = pathChunks.removeLast()
			
			// Get the raw path
			let path = fullPath.replacingOccurrences(of: nameAndExt, with: "")
			let name = nameAndExt.components(separatedBy: ".").first!
			var ext = nameAndExt.components(separatedBy: ".").last!
			ext = "." + ext
			
			// Try getting the URL
			guard let url = bundle!.url(forResource: name, withExtension: ext, subdirectory: path)
				else {
					print(CacheError.LocalNotFound.rawValue)
					return nil
			}
			
			// Try getting the bytes
			do {
				let image = try Data(contentsOf: url)
				let bytes = image.makeBytes()
				return bytes
				
			} catch {
				print(CacheError.LocalNotFound.rawValue)
				return nil
			}
			
			
		default:
			return nil
		}
	}
}
