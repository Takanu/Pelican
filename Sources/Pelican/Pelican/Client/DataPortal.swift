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
	//var target: SessionTag
	
	// URLSESSION DATA
	var request: URLRequest
	var dataTask: URLSessionDataTask?
	var portal: Portal<TelegramResponse>?
	
	// PORTAL DATA
	var semaphore = DispatchSemaphore(value: 0)
	
	
	init(_ request: URLRequest) throws {
		
		self.request = request
		
	}
	
	public func openSync(session: URLSession) throws -> TelegramResponse {
		
		do {
			// Open the portal! \o/
			let response = try Portal<TelegramResponse>.open(timeout: timeout.rawValue) { portal in
				print("PORTAL: Assigning data task...")
				
				self.dataTask = self.session.dataTask(with: request) { (data, urlResponse, error) in
					
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
			
			//if error == PortalError.timedOut {
				// *shrug*
			//}
			
		}
	}
	
	public func openAsync(session: URLSession, callback: ((TelegramResponse) -> ())? ) throws {
		
		self.dataTask = session.dataTask(with: request) { (data, urlResponse, error) in
			
			if let error = error {
				return
			}
			
			// Convert the data to useful types if successful
			if let data = data {
				
				let httpResponse = urlResponse as! HTTPURLResponse
				let response = TelegramResponse(data: data, urlResponse: httpResponse)
				
				print("URLSESSION - Task Complete.")
				
				if callback != nil {
					callback(response)!
				}
			}
		}
	}
	
}
