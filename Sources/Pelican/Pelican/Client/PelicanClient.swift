//
//  PelicanClient.swift
//  Pelican
//
//  Created by Ido Constantine on 21/02/2018.
//

import Foundation
import HTTP

/**
Allows Pelican to make Telegram API methods either synchronosly or asynchronously, using URLSession.

It also keeps track of all requests, automatically times out any requests that don't receive a response in a
fast enough time and attempts to resolve any errors where possible.
*/
class PelicanClient {
	
	/// The URLSession to be used for data tasks
	var session: URLSession!
	
	/// The length of time any client connection is allowed to be active before it's cancelled and the client makes another attempt.
	var connectionTimeout: Duration = 3.sec
	
	/// The data task currently being performed
	var dataTask: URLSessionDataTask?
	
	/// The time taken to perform the data task
	public var requestTime: TimeInterval?

	
	init() {
		
		let config = URLSessionConfiguration.ephemeral
		config.httpCookieStorage = nil
		config.httpMaximumConnectionsPerHost = 20
		config.isDiscretionary = false
		//config.shouldUseExtendedBackgroundIdleMode = false
		config.networkServiceType = .default
		//config.waitsForConnectivity = true
		
		/// Assigning the delegate queue is a bad idea.  Don't do it unless you know what you're doing.
		session = URLSession(configuration: config)
	}

	
	/**
	Makes a client request while waiting for a return value instead of immediately returning without waiting for a response.
	*/
	private func syncRequest(request: Request, next: @escaping (Response?) -> ()) {
		
		dataTask?.cancel()
		let url = try! request.uri.makeFoundationURL()
		let urlRequest = URLRequest(url: url)
		
		print("URLSESSION - Preparing task...")
		
		
		
		next(response)
		
	}
	
	
	
	func getResponse(request: Request, next: @escaping (Response?) -> ()) {
		
		
		
		dataTask?.cancel()
		
		print("URLSESSION - Preparing task...")
		print(request)
		
		self.dataTask = self.session.dataTask(with: url) { (data, urlResponse, error) in
			
			if let data = data {
				// Convert the data to JSON
				let response = self.makeVaporResponse(data: data, urlResponse: urlResponse!)
				
				print(response)
				print("URLSESSION - Task Complete.")
				next(response)
			}
		}
		
		print("URLSESSION - Sending task...")
		self.dataTask?.resume()
		
	}
}

