//
//  ClientConnection.swift
//  Pelican
//
//  Created by Takanu Kyriako on 06/03/2018.
//

import Foundation



/**
Encapsulates an active method request with a URLSession data task.

- Enables both synchronous and asynchronous data task execution.
- Enables external cancellation of data tasks (?)
- Features timeout handling
*/
final public class ClientConnection {
	
	// CONFIGURATION
	/// The length of time a normal data task will remain open before the connection automatically closes.
	var timeout = 60.sec
	
	/// The amount of times a connection will attempt to re-connect before giving up and returning nil.
	var reconnectAttempts = 3
	
	
	// REQUEST DATA
	//var target: SessionTag
	
	
	// URLSESSION DATA
	/// The request being made to
	var request: URLRequest
	
	/// The data task created to perform the client connection task.
	var dataTask: URLSessionDataTask?
	
	var portal: Portal<TelegramResponse>?
	
	
	// PORTAL DATA
	/// A unique ID that can be used to compare ClientConnection instances.
	let id = UUID()
	
	/// If true, the portal is currently attempting to complete a request.  If not, it has either finished or is waiting to start.
	var isActive = false
	
	
	// CONNECTION STATUS
	/// If connecting asynchronously, the callback to be used if the request needs to be sent again.
	var callback: ((TelegramResponse?) -> ())?
	
	/// The number of times the ClientConnection has timed out and attempted to reconnect.
	var currentReconnectAttempts = 0
	
	
	/// ???
	///var semaphore = DispatchSemaphore(value: 0)
	
	
	init(_ request: URLRequest) {
		
		self.request = request
		
	}
	
	/**
	Opens a synchronous client connection to Telegram.
	*/
	public func openSync(session: URLSession) throws -> TelegramResponse? {
		
		do {
			// Open the portal! \o/
			let response = try Portal<TelegramResponse>.open(timeout: self.timeout.rawValue) { portal in
				self.isActive = true
				
				// Set the data task at hand
				self.dataTask = session.dataTask(with: self.request) { (data, urlResponse, error) in
					
					if let error = error {
						portal.close(with: error)
						return
					}
					
					// Convert the data to useful types if successful
					if let data = data {
						do {
							let httpResponse = urlResponse as! HTTPURLResponse
							let response = try TelegramResponse(data: data, urlResponse: httpResponse)
							
							portal.close(with: response)
							return
							
						} catch {
							portal.close(with: error)
							return
						}
						
					}
				}
				
				// Send the task
				self.dataTask?.resume()
			}
			
			// When the portal has escaped, cancel the data task just in case and return.
			self.dataTask?.cancel()
			return response
			
		} catch {
			if error is PortalError {
				let portalError = error as! PortalError
				
				if portalError == .timedOut {
					currentReconnectAttempts += 1
					
					if currentReconnectAttempts < reconnectAttempts {
						print("ClientConnection - Timed out, retrying...")
						self.dataTask?.cancel()
						return try openSync(session: session)
					}
					
					else {
						print("ClientConnection - Run out of reconnection attempts")
						throw PortalError.timedOut
					}
				}
			}
			
			return nil
		}
	}
	
	
	/**
	Opens an asynchronous client connection to Telegram.
	*/
	public func openAsync(session: URLSession, callback: ((TelegramResponse?) -> ())? ) throws {
		
		self.callback = callback
		
		self.dataTask = session.dataTask(with: request) { (data, urlResponse, error) in
			
			if let error = error {
				print(error)
				return
			}
			
			// Convert the data to useful types if successful
			if let data = data {
				
				do {
					let httpResponse = urlResponse as! HTTPURLResponse
					let response = try TelegramResponse(data: data, urlResponse: httpResponse)
					
					print("ClientConnection - Task Complete.")
					
					if callback != nil {
						callback!(response)
						self.isActive = false
						return
					}
				} catch {
					print(error)
					return
				}
				
				
			}
		}
		
		isActive = true
		self.dataTask?.resume()
	}
	
	/**
	Cleans the temporary connection states.
	*/
	func clean() {
		currentReconnectAttempts = 0
	}
		
	/**
	Overridden to catch timeout errors.
	*/
	/*
	override func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		
		if error == nil {
			return
		}
		
		if error! is URLError {
			let urlError = error as! URLError
			
			// Timeout Handling
			if urlError == .timedOut {
				
				currentReconnectAttempts += 1
				
				if currentReconnectAttempts < reconnectAttempts {
					print("ClientConnection - Timed out, retrying...")
					return try openAsync(session: session, callback: self.callback)
				}
					
				else {
					print("ClientConnection - Run out of reconnection attempts")
					throw PortalError.timedOut
				}
			}
			
			
			
		}
	}
*/
	
}
