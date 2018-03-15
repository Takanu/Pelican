//
//  ShippingQuery.swift
//  Pelican
//
//  Created by Ido Constantine on 18/12/2017.
//

import Foundation


/**
Contains information about an incoming shipping query for the Telegram Payment API.
*/
public class ShippingQuery: Codable {
	
	/// Unique query identifier.
	var id: String = ""
	
	/// The user who sent this query.
	var from: User = User(id: 0, isBot: false, firstName: "fixme")
	
	/// The bot-specified invoice payload.
	var invoicePayload: String = ""
	
	/// The user-specified shipping address.
	var shippingAddress: ShippingAddress = ShippingAddress()
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case id
		case from
		case invoicePayload = "invoice_payload"
		case shippingAddress = "shipping_address"
	}
	
}
