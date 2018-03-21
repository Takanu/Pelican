//
//  CacheManager.swift
//  Pelican
//
//  Created by Takanu Kyriako on 21/08/2017.
//

import Foundation

/**
Manages a database of currently active file links for re-use, as well as asynchronously uploads content
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
	
	init(bundlePath: String) throws {
		self.bundle = Bundle(path: bundlePath + "/Resources")
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
	func fetchFile(path: String) throws -> Data {
		
		if path.contains("://") {
			
		}
			
		else {
			if bundle == nil {
				throw CacheError.BadBundle
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
					throw CacheError.LocalNotFound
			}
			
			// Try getting the bytes
			do {
				let data = try Data(contentsOf: url)
				return data
				
			} catch {
				throw CacheError.LocalNotFound
			}
		}
		
		throw CacheError.NoBytes
	}
	
	/**
	Attempts to retrieve data on the given MessageFile that would allow it to be send in a Telegram Request.

	- returns: An header tuple containing the correct header field and value, and a body data type containing the body that should be supplied to the URLRequest.
	*/
	func getRequestData(forFile file: MessageFile, query: [String: Encodable], url: URL) throws -> URLRequest? {
		
		// If there's a file ID, send the ID as part of the body.
		if file.fileID != nil {
			
			let boundary = generateBoundary()
			var urlRequest = URLRequest(url: url)
			urlRequest.httpMethod = "POST"
			
			// Using setValue instead of addValue ensures that if the header field already exists, it is overwritten.
			urlRequest.setValue("text/html; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
			urlRequest.httpBody = try createDataBody(withParameters: query, file: nil, boundary: boundary)
			if urlRequest.httpBody == nil { throw CacheError.NoBytes }
			return urlRequest
		}
		
		// If theres a URL, we need to fetch or validate the file.
		else if file.url != nil {
			
			let boundary = generateBoundary()
			var urlRequest = URLRequest(url: url)
			urlRequest.httpMethod = "POST"
			urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
			print(query)
			
			var body: Data
			do {
				body = try createDataBody(withParameters: query, file: file, boundary: boundary)
			} catch {
				throw error
			}
			
			urlRequest.setValue(String(body.count), forHTTPHeaderField: "Content-Length")
			urlRequest.httpBody = body
			urlRequest.httpShouldHandleCookies = false
			return urlRequest
		}
		
		// Otherwise, throw a niiiiice big error.
		throw CacheFormError.LinkNotFound
	}
	
	
	/**
	Generates a boundary to suit the formatting requirements for sending multipart form-data over HTTP.
	This lets the server receiving the request know that the data is all part of the same request.
	
	(The boundary uses UUID to ensure a unique boundary for every request, for security reasons)
	*/
	private func generateBoundary() -> String {
		return "Boundary-\(UUID().uuidString)"
	}
	
	
	/**
	Creates a data body for files, to be sent as multipart form-data.
	- paramater withParameters: Optional paramters to be sent before the multipart form-data.
	- parameter file: The file to be turned into body data.
	- parameter boundary:
	*/
	private func createDataBody(withParameters params: [String: Encodable]?, file: MessageFile?, boundary: String) throws -> Data {
		
		let lineBreak = "\r\n"
		var body = Data()
		
		// Add any optional parameters
		if let parameters = params {
			for (key, value) in parameters {
			
				guard let encodedValue = try value.encodeToUTF8() else { continue }
				
				body.append("--\(boundary + lineBreak)")
				body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
				body.append("\(encodedValue + lineBreak)")
			}
		}
		
		// Fetch the contents of the file
		if file == nil { return body }
		if file!.url == nil { return body }
		
		// Fetch the file data and break up the path into names.
		let fullFileName = file!.url?.components(separatedBy: "/").last ?? ""
		let fileName = fullFileName.components(separatedBy: ".").first ?? ""
		
		let typeName = file!.contentType
		let fileData = try fetchFile(path: file!.url!)
		let mimeType = "text/plain"			// Can be upgraded later once MessageType is more sophisticated.
		
		// Build the body
		body.append("--\(boundary + lineBreak)")
		body.append("Content-Disposition: form-data; name=\"\(typeName)\"; filename=\"\(fileName)\"\(lineBreak)")
		body.append("Content-Type: \(mimeType + lineBreak + lineBreak)")
		
		print(String.init(data: body, encoding: .utf8)!)
		body.append(fileData)
		body.append(lineBreak)
		
		body.append("--\(boundary)--\(lineBreak)")
		
		
		return body
		
	}
}


extension Data {
	mutating func append(_ string: String) {
		if let data = string.data(using: .utf8) {
			append(data)
		}
	}
}
