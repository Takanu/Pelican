//
//  KeyboardKey.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

/// Represents a single key of a MarkupKeyboard.
final public class MarkupKeyboardKey: Model {
	public var storage = Storage()
	
	/// The text displayed on the button.  If no other optional is used, this will be sent to the bot when pressed.
	public var text: String
	/// (Optional) If True, the user's phone number will be sent as a contact when the button is pressed. Available in private chats only.
	private var requestContact: Bool = false
	// (Optional) If True, the user's current location will be sent when the button is pressed. Available in private chats only.
	private var requestLocation: Bool = false
	
	init(label: String) {
		text = label
	}
	
	// Ignore context, just try and build an object from a node.
	public init(row: Row) throws {
		text = try row.get("text")
		requestContact = try row.get("request_contact") ?? false
		requestLocation = try row.get("request_location") ?? false
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("text", text)
		try row.set("request_contact", requestContact)
		try row.set("request_location", requestLocation)
		
		return row
	}
}
