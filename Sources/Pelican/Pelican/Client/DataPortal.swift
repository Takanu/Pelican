//
//  DataPortal.swift
//  Pelican
//
//  Created by Ido Constantine on 06/03/2018.
//

import Foundation
import HTTP

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
					
					if let data = data {
						// Convert the data to JSON
						let httpResponse = urlResponse as! HTTPURLResponse
						
						let body = data.makeBytes()
						var headers: [HeaderKey: String] = [:]
						
						httpResponse.allHeaderFields.forEach { tuple in
							headers[HeaderKey("\(tuple.key)")] = "\(tuple.value)"
						}
						
						
						let status = Status(statusCode: httpResponse.statusCode)
						let response = Response(status: status, headers: headers, body: Body(body))
						
						//print(response)
						print("URLSESSION - Task Complete.")
						
						//let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : String]
						//response = Response(urlResponse: urlResponse, data: data)
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
			
			if let data = data {
				// Convert the data to JSON
				let httpResponse = urlResponse as! HTTPURLResponse
				
				let body = data.makeBytes()
				var headers: [HeaderKey: String] = [:]
				
				httpResponse.allHeaderFields.forEach { tuple in
					headers[HeaderKey("\(tuple.key)")] = "\(tuple.value)"
				}
				
				
				let status = Status(statusCode: httpResponse.statusCode)
				let response = Response(status: status, headers: headers, body: Body(body))
				
				//print(response)
				print("URLSESSION - Task Complete.")
				callback()
			}
		}
	}
	
	/**
	Taken from Vapor's HTTP Module to exchange a Vapor Request for a URLRequest.
	*/
	public func makeFoundationRequest(_ request: Request) throws -> URLRequest {
		let url = try request.uri.makeFoundationURL()
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = request.method.description.uppercased()
		urlRequest.httpBody = request.body.bytes.flatMap { Data(bytes: $0) }
		request.headers.forEach { key, val in
			urlRequest.addValue(val, forHTTPHeaderField: key.description)
		}
		return urlRequest
	}
	
	/**
	Taken from Vapor's HTTP Module to exchange a set of Data and a URLResponse into a nice Vapor Response.
	*/
	public func makeVaporResponse(data: Data, urlResponse: URLResponse) -> Response {
		let httpResponse = urlResponse as! HTTPURLResponse
		
		//let bodyText = data.makeBytes().makeString().percentDecoded
		
		let body = data.makeBytes()
		var headers: [HeaderKey: String] = [:]
		
		httpResponse.allHeaderFields.forEach { tuple in
			headers[HeaderKey("\(tuple.key)")] = "\(tuple.value)"
		}
		
		
		let status = Status(statusCode: httpResponse.statusCode)
		return Response(status: status, headers: headers, body: Body(body))
	}
	
	
	
}
