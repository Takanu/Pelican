//
//  User.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

/**
Represents a Telegram user or bot.
*/
final public class User: Model {
	public var storage = Storage() // The type used for the model to identify between database entries
	public var messageTypeName = "user"
	
	/// Unique identifier for the user or bot.
	public var tgID: Int
	/// User's or bot's first name.
	public var firstName: String
	/// (Optional) User's or bot's last name.
	public var lastName: String?
	/// (Optional) User's or bot's username.
	public var username: String?
	/// (Optional) IETF language tag of the user's language.
	public var languageCode: String?
	
	public init(id: Int, firstName: String) {
		self.tgID = id
		self.firstName = firstName
	}
	
	// NodeRepresentable conforming methods to transist to and from storage.
	public required init(row: Row) throws {
		
		// Tries to extract depending on what context is being used (I GET IT NOW, CLEVER)
		tgID = try row.get("id")
		firstName = try row.get("first_name")
		lastName = try row.get("last_name")
		username = try row.get("username")
		languageCode = try row.get("language_code")
		
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("id", tgID)
		try row.set("first_name", firstName)
		try row.set("last_name", lastName)
		try row.set("username", username)
		try row.set("language_code", languageCode)
		return row
	}
}
