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
	public var storage: [String: Any]

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
	init?(response: Response)	{
		
		let json = response.json!
		
		if json["ok"] != nil {
			self.success = json["ok"]!.bool!
		} else {
			return nil
		}
		
		// If the request wasn't successful, fetch information about why it wasn't
		if success == false {
			do {
				
				if json["description"] != nil {
					self.errorDescription = try json["description"]!.serialize().makeString()
				}
				
				if json["error_code"] != nil {
					self.errorCode = try json["error_code"]!.serialize().makeString()
				}
				
			} catch {
				PLog.error("Telegram Response Creation Error - \(error)")
				return nil
			}
		}
		
		// If it was, set the result.
		else {
			do {
				self.data = Data.init(bytes: try json["result"]!.makeBytes().array)
			} catch {
				PLog.error("Telegram Response Creation Error - \(error)")
				return nil
			}
			
		}
	}
}
