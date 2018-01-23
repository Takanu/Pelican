//
//  InputMessageContent.swift
//  Pelican
//
//  Created by Ido Constantine on 19/12/2017.
//

import Foundation

/**
Represents the content of a message to be sent as a result of an inline query.  This contains all types
*/
public class InputMessageContent: Codable {
	
	public var type: InputMessageContentType
	public var base: InputMessageContent_Any
	
	// These values are only ever used to detect what content type is being held.
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case type
		case base
		case phoneNumber = "phone_number"
		case latitude
		case text = "message_text"
		case address
	}
	
	public init(content: InputMessageContent_Any) {
		
		base = content
		
		if content is InputMessageContent_Venue { type = .venue }
		
		else if content is InputMessageContent_Location { type = .location }
		
		else if content is InputMessageContent_Contact { type = .contact }
		
		else { type = .text }
	}
	
	
	public required init(from decoder: Decoder) throws {
		
		// This decoder attempts to find a unique and required key from the given content, and uses that to
		// initialise the correct
		let values = try decoder.container(keyedBy: CodingKeys.self)
		let keys = values.allKeys
		
		if keys.contains(.phoneNumber) {
			type = .contact
		}
			
		else if keys.contains(.address) {
			type = .venue
		}
		
		else if keys.contains(.latitude) {
			type = .location
		}
		
		else {
			type = .text
		}
		
		base = try type.metatype.init(from: decoder)
	}
	
	public func encode(to encoder: Encoder) throws {
		try base.encode(to: encoder)
	}
}




