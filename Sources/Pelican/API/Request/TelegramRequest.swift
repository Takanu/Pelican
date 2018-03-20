//
//  TelegramRequest.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 10/07/2017.
//
//

import Foundation

/**
Encapsulates all required information to make an API request to Telegam.

The TelegramRequest type also contains via static declarations all possible methods that are available in the Telegram API.  These
can be used to fabricate a TelegramRequest for a specific method call.

To send a TelegramRequest, use `Client.syncRequest` or `Client.asyncRequest`.  Alternatively if programming bot events in a Session, just use the included
SessionRequest type to make the `TelegramRequest`, send it and return you the right result.
*/
public class TelegramRequest {
	
	/// The name of the Telegram method.
	public var method: String = ""
	
	/// The queries to be used as arguments for the request.
	public var query: [String: Encodable] = [:]
	
	/// If the method is uploading a file, the type to be uploaded.
	var file: MessageFile?
	
	/// An optional field for the content that's included to define what the content of the request is, if in a String format.
	var content: Any?
	
	enum TelegramRequestError: String, Error {
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
		uri.host = "api.telegram.org"
		uri.port = 443
		uri.path = "/bot\(apiToken)/\(method)"
		
		var querySets: [URLQueryItem] = []
		
		for item in query {
			let value = try item.value.encodeToUTF8()
			querySets.append(URLQueryItem(name: item.key, value: value))
		}
		
		uri.queryItems = querySets

		guard let url = uri.url else { throw TelegramRequestError.unableToMakeFoundationURL }
		
		
		/// Build the request
		var urlRequest = URLRequest(url: url)
		
		/// If we have message content, get the information as part of an HTTP body.
		if file != nil {
			urlRequest.httpBody = try cache.getRequestData(forFile: file!, query: query)
		}
		
		return urlRequest
	}
}

