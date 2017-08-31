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
	public var storage = Storage()
	public var contentType: String = "contact" // MessageType conforming variable for Message class filtering.
	public var method: String = "/sendContact" // SendType conforming variable for use when sent
	
	public var phoneNumber: String
	public var firstName: String
	public var lastName: String?
	public var userID: Int?
	
	public init(phoneNumber: String, firstName: String) {
		self.phoneNumber = phoneNumber
		self.firstName = firstName
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
	
	// NodeRepresentable conforming methods
	public required init(row: Row) throws {
		phoneNumber = try row.get("phone_number")
		firstName = try row.get("first_name")
		lastName = try row.get("last_name")
		userID = try row.get("user_id")
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("phone_number", phoneNumber)
		try row.set("first_name", firstName)
		try row.set("last_name", lastName)
		try row.set("user_id", userID)
		
		return row
	}
}
