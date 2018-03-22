//
//  KeyboardKey.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



/// Represents a single key of a MarkupKeyboard.
final public class MarkupKeyboardKey: Codable, Equatable {
	
	/// The text displayed on the button.  If no other optional is used, this will be sent to the bot when pressed.
	public var text: String
	
	/// (Optional) If True, the user's phone number will be sent as a contact when the button is pressed. Available in private chats only.
	public var requestContact: Bool = false
	
	// (Optional) If True, the user's current location will be sent when the button is pressed. Available in private chats only.
	public var requestLocation: Bool = false
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case text
		case requestContact = "request_contact"
		case requestLocation = "request_location"
	}
	
	
	init(text: String) {
		self.text = text
	}
	
	init(withLocationRequest requestLocation: Bool, text: String) {
		self.text = text
		self.requestLocation = requestLocation
	}
	
	init(withContactRequest requestContact: Bool, text: String) {
		self.text = text
		self.requestContact = requestContact
	}
	
	static public func ==(lhs: MarkupKeyboardKey, rhs: MarkupKeyboardKey) -> Bool {
		if lhs.text != rhs.text { return false }
		if lhs.requestContact != rhs.requestContact { return false }
		if lhs.requestLocation != rhs.requestLocation { return false }
		
		return true
	}
}
