//
//  Pelican+Client.swift
//  Pelican
//
//  Created by Ido Constantine on 04/11/2017.
//

import Foundation
import Vapor
import TLS
import Dispatch

extension Pelican {
	
	func connectToClient(request: Request, attempts: Int) -> Response? {
		
		var response: Response? = nil
		var requestLimit: Int = attempts
		var requestCount: Int = 0
		
		func attemptConnection() {
		
			// Attempt a connection to the client
			do {
				response = try client!.respond(to: request)
				
				if response == nil {
					PLog.error("Client connection failed, no response.  \nRetrying...")
				}
			}
				
			// Handle the error
			catch {
				
				// If it's a TLS Error, handle separately
				if error is TLSError {
					let tlsError = error as! TLSError
					
					// If there's a read error, the connection has been closed and we need to rebuild it.
					if tlsError.functionName == "SSL_read" {
						
						PLog.error("Client connection exited - \(error).  \nRebuilding connection...\n")
						if self.clientType == "foundation" {
							self.client = try! drop!.client.makeClient(hostname: "api.telegram.org", port: 443, securityLayer: .tls(context!), proxy: .none)
						}
							
						else {
							self.client = try! drop!.client.makeClient(hostname: "api.telegram.org", port: 443, securityLayer: .tls(context!), proxy: .none)
						}
					}
				}
			}
			
			// If we ended up with no response, try again
			if response == nil {
				requestCount += 1
				
				if requestCount < requestLimit || requestLimit == 0 {
					Thread.sleep(forTimeInterval: 0.1 * Double(requestCount))
					attemptConnection()
				}
			}
		}
		
		attemptConnection()
		return response
	}
}
