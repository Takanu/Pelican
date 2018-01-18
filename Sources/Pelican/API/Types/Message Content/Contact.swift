//
//  Contact.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

final public class Contact: TelegramType, MessageContent {
	
	// STORAGE AND IDENTIFIERS
	public var contentType: String = "contact"
	public var method: String = "sendContact"
	
	// PARAMETERS
	/// The contact's phone number.
	public var phoneNumber: String
	
	/// The contact's first name.
	public var firstName: String
	
	/// The contact's last name
	public var lastName: String?
	
	/// The contact's user ID
	public var userID: Int?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case phoneNumber = "phone_number"
		case firstName = "first_name"
		case lastName = "last_name"
		case userID = "user_id"
		
	}
	
	public init(phoneNumber: String, firstName: String, lastName: String? = nil, userID: Int? = nil) {
		self.phoneNumber = phoneNumber
		self.firstName = firstName
		self.lastName = lastName
		self.userID = userID
	}
	
	
	// SendType conforming methods to send itself to Telegram under the provided method.
	public func getQuery() -> [String:NodeConvertible] {
		var keys: [String:NodeConvertible] = [
			"phone_number": phoneNumber,
			"first_name": firstName
		]
		
		if lastName != nil { keys["last_name"] = lastName }
		
		return keys
	}
}
