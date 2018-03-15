//
//  ShippingAddress.swift
//  Pelican
//
//  Created by Ido Constantine on 18/12/2017.
//

import Foundation


/**
Represents a shipping address for the Telegram Payment API.
*/
public class ShippingAddress: Codable {
	
	/// ISO 3166-1 alpha-2 country code.
	var countryCode: String = ""
	
	/// The state, if applicable.
	var state: String?
	
	var city: String = ""
	var streetLine1: String = ""
	var streetLine2: String = ""
	var postCode: String = ""
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case countryCode = "country_code"
		case state
		case city
		case streetLine1 = "street_line_1"
		case streetLine2 = "street_line_2"
		case postCode = "post_code"
	}
	
}
