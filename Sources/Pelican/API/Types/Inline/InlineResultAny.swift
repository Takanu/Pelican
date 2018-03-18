//
//  File.swift
//  Pelican
//
//  Created by Takanu Kyriako on 23/01/2018.
//

import Foundation


/**
Defines a wrapper for the InlineResult protocol, that allows ambiguous InlineResult types to be encoded and decoded.
*/
public class InlineResultAny: Codable {
	
	public var base: InlineResult
	public var type: InlineResultType
	
	// These values are only ever used to infer what content type is being held.
	enum CodingKeys: String, CodingKey {
		case type
	}
	
	init(_ base: InlineResult) {
		self.base = base
		self.type = base.metatype
	}
	
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		/// Create a new result type from the convenient "type" property.
		if let type = InlineResultType(rawValue: try container.decode(String.self, forKey: .type)) {
			
			/// Use that metatype to initialise the base.
			self.type = type
			self.base = try type.metatype.init(from: decoder)
			return
			
		} else {
			throw PError_Codable.InlineResultAnyDecodable
		}
	}
	
	public func encode(to encoder: Encoder) throws {
		try base.encode(to: encoder)
	}
	
}
