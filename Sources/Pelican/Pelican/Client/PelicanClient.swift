//
//  PelicanClient.swift
//  Pelican
//
//  Created by Ido Constantine on 21/02/2018.
//

import Foundation


/**
Allows Pelican to make Telegram API methods either synchronosly or asynchronously, using URLSession.

It also keeps track of all requests, automatically times out any requests that don't receive a response in a
fast enough time and attempts to resolve any errors where possible.
*/
class PelicanClient {
	
	/// The API token of the bot this current instance of Pelican is responsible for.
	var token: String
	
	/// The URLSession to be used for data tasks
	var session: URLSession!
	
	/// The length of time any client connection is allowed to be active before it's cancelled and the client makes another attempt.
	var connectionTimeout: Duration = 3.sec
	
	/// The data task currently being performed
	var dataTask: URLSessionDataTask?
	
	/// The time taken to perform the data task
	public var requestTime: TimeInterval?
	
	/// A reference to the CacheManager required to store and update FileIDs of files and optimise file sending.
	var cache: CacheManager

	
	init(token: String, cache: CacheManager) {
		
		self.token = token
		self.cache = cache
		
		let config = URLSessionConfiguration.ephemeral
		config.httpCookieStorage = nil
		config.httpMaximumConnectionsPerHost = 20
		config.isDiscretionary = false
		//config.shouldUseExtendedBackgroundIdleMode = false
		config.networkServiceType = .default
		//config.waitsForConnectivity = true
		
		/// Assigning the delegate queue is a bad idea.  Don't do it unless you know what you're doing.  Which we're not.
		session = URLSession(configuration: config)
	}

	
	/**
	Makes a synchronous client request.  This will block thread execution until a response is received,
	but you will be able to directly receive a TelegramResponse and handle it on the same thread.
	*/
	func syncRequest(request: TelegramRequest) throws -> TelegramResponse {
		
		let urlrequest = try request.makeURLRequest(token, cache: cache)
		
		print("URLSESSION - Preparing task...")
	}
	
	/**
	Makes an asynchronous client request which will not block thread code execution.
	An optional closure can be provided to handle the result once a response is received.
	*/
	func asyncRequest(request: TelegramRequest, next: ((TelegramResponse) -> ())? ) throws {
		
		let urlrequest = try request.makeURLRequest(token, cache: cache)
		
		
		
	}
}

