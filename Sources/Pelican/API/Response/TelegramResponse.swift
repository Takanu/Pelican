//
//  TelegramResponse.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 11/07/2017.
//
//

import Foundation

/**
Represents a response from Telegram servers once a request has been made.
*/
public class TelegramResponse {

	// HTTP CORE
	/// The HTTP Version.
	public var version: Version
	
	/// The status of the request.
	public var status: Status
	
	/// HTTP response headers.
	public var headers: [String: String]
	
	/// HTTP body.
	public var body: Data
	
	/// ???
	//public var storage: [String: Any]

	/// The date the response was received.
	var date = Date()
	
	
	// TELEGRAM STATUS
	/// The error description, if the request was unsuccessful.
	var tgStatus: String?
	
	/// The Telegram code sent back as a
	var tgCode: String?

	/**
	Converts a response received from a Telegram Request to a response type.
	- parameter response: The Vapor.Response type returned from a Telegram API request.  Failing
	to provide the correct response will result in a runtime error.
	*/
	init(data: Data, urlResponse: HTTPURLResponse)	{
		
		//self.version = urlResponse.v
		self.status = Status(statusCode: urlResponse.statusCode)
		urlResponse.allHeaderFields.forEach { tuple in
			self.headers["\(tuple.key)"] = "\(tuple.value)"
		}
		
		self.body = data
		
	}
}
