//
//  TelegramRequest.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 10/07/2017.
//
//

import Foundation

/**
Catalogues all possible methods that are available in the Telegram API through static functions, whilst 
providing properties for wrapping created function data from within the type to.
*/
public class TelegramRequest {
	
	/// The name of the Telegram method.
	public var method: String
	
	/// The queries to be used as arguments for the request.
	public var query: [String: String] = [:]
	
	/// If the method is uploading a file, the type to be uploaded.
	var file: MessageFile?
	
	/// An optional field for the content that's included to define what the content of the request is, if in a String format.
	var content: Any?
	
	
	public enum ConversionError: Error {
		case unableToMakeFoundationURL
	}
	
	
	init() {}
	
	
	/**
	Builds a URLRequest based on the contents of this TelegramRequest type.
	
	- parameter apiToken: The API token for the bot.
	- parameter cache: The CacheManager held by your Pelican instance, to check if a file upload is necessary when requested.
	*/
	func makeURLRequest(_ apiToken: String, cache: CacheManager) throws -> URLRequest {
		
		/// Build the URL
		var uri = URLComponents()
		uri.scheme = "https"
		//uri.user = userInfo?.username
		//uri.password = userInfo?.info
		uri.host = "api.telegram.org"
		uri.port = 443
		uri.path = "/bot\(apiToken)/\(method)"
		
		var querySets: [URLQueryItem] = []
		for item in query {
			querySets.append(URLQueryItem(name: item.key, value: item.value))
		}
		uri.queryItems = querySets

		guard let url = uri.url else { throw ConversionError.unableToMakeFoundationURL }
		
		
		/// Build the request
		var urlRequest = URLRequest(url: url)
		
		/// If we have message content, get the information as part of an HTTP body.
		if file != nil {
			let reqData = cache.getRequestData(forFile: file!)
			urlRequest.addValue(reqData.header.1, forHTTPHeaderField: reqData.header.0)
			urlRequest.httpBody = reqData.body
		}
		
		return urlRequest
	}
}

