//
//  InputMessageContact.swift
//  Pelican
//
//  Created by Ido Constantine on 19/12/2017.
//

import Foundation

final public class InputMessageContent_Contact: InputMessageContent_Any {
	
	// The type of the input content, used for Codable.
	public static var type: InputMessageContentType = .contact
	
	// Contact's phone number.
	public var phoneNumber: String
	
	// Contact's first name.
	public var firstName: String
	
	// Contact's last name.
	public var lastName: String
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case phoneNumber = "phone_number"
		case firstName = "first_name"
		case lastName = "last_name"
	}
	
	init(phoneNumber: String, firstName: String, lastName: String) {
		self.phoneNumber = phoneNumber
		self.firstName = firstName
		self.lastName = lastName
	}
	
}
