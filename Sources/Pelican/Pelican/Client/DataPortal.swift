//
//  DataPortal.swift
//  Pelican
//
//  Created by Ido Constantine on 06/03/2018.
//

import Foundation



/**
Encapsulates an active method request with a URLSession data task.

- Enables both synchronous and asynchronous data task execution.
- Enables external cancellation of data tasks
*/
final public class DataPortal {
	
	// STATIC CONFIGURATION
	/// The length of time a normal data task will remain open before the connection automatically closes.
	static var timeout = 5.sec
	
	// REQUEST DATA
	/// The TelegramRequest type used to make this request.
	var request: TelegramRequest
	//var target: SessionTag
	
	// URLSESSION DATA
	var urlRequest: URLRequest
	var dataTask: URLSessionDataTask?
	var portal: Portal<Response>?
	
	// PORTAL DATA
	var semaphore = DispatchSemaphore(value: 0)
	
	
	init(_ request: TelegramRequest) throws {
		
		self.request = request
		
		let url = try! request.uri.makeFoundationURL()
		let urlRequest = URLRequest(url: url)
		
	}
	
	public func openSync(session: URLSession) throws -> Response {
		
		do {
			// Open the portal! \o/
			let response = try Portal<Response>.open(timeout: timeout.rawValue) { portal in
				print("PORTAL: Assigning data task...")
				
				self.dataTask = self.session.dataTask(with: urlRequest) { (data, urlResponse, error) in
					
					if let error = error {
						print("PORTAL: Closing with error...")
						portal.close(with: error)
						return
					}
					
					// Convert the data to useful types if successful
					if let data = data {
						
						let httpResponse = urlResponse as! HTTPURLResponse
						let response = TelegramResponse(data: data, urlResponse: httpResponse)
						portal.close(with: response)
					}
				}
				
				print("URLSESSION - Sending task...")
				self.dataTask?.resume()
			}
		} catch {
			
			if error == SyncPortalError.timedOut {
				// *shrug*
			}
			
		}
	}
	
	public func openAsync(session: URLSession, callback: () -> ()) throws {
		
		self.dataTask = session.dataTask(with: urlRequest) { (data, urlResponse, error) in
			
			if let error = error {
				return
			}
			
			// Convert the data to useful types if successful
			if let data = data {
				
				let httpResponse = urlResponse as! HTTPURLResponse
				let response = TelegramResponse(data: data, urlResponse: httpResponse)
				
				//print(response)
				print("URLSESSION - Task Complete.")
				callback()
			}
		}
	}
	
}
