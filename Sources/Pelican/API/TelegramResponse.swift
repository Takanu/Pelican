//
//  TelegramResponse.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 11/07/2017.
//
//

import Foundation
import Vapor

/**
Represents a response from Telegram servers once a request has been made.
*/
public class TelegramResponse {

	// Whether the request was a success or not
	public private(set) var success: Bool
	// The data contained, if available.
	public private(set) var data: Node?

	/**
	Converts a response received from a Telegram Request to a response type.
	- parameter response: The Vapor.Response type returned from a Telegram API request.  Failing
	to provide the correct response will result in a runtime error.
	*/
	init(response: Response)	{
		
		let node = response.json!.makeNode(in: nil)
		
		self.data = node["result"]
		self.success = node["ok"]!.bool!
		
	}
}
