//
//  InputMessageContentType.swift
//  Pelican
//
//  Created by Takanu Kyriako on 22/12/2017.
//

import Foundation

public enum InputMessageContentType: String {
	
	case contact
	case location
	case text
	case venue
	
	/// Helps us define what we need to encode and decode later.
	var metatype: InputMessageContent_Any.Type {
		switch self {
		case .contact:
			return InputMessageContent_Contact.self
		case .location:
			return InputMessageContent_Location.self
		case .text:
			return InputMessageContent_Text.self
		case .venue:
			return InputMessageContent_Venue.self
		}
	}
}
