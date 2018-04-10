//
//  OrderInfo.swift
//  Pelican
//
//  Created by Takanu Kyriako on 18/12/2017.
//

import Foundation


/**
This object represents information about an order for the Telegram Payment API.
*/
public struct OrderInfo: Codable {
	
	/// The user's name
	var name: String?
	
	/// The user's phone number.
	var phoneNumber: String?
	
	/// The user's email.
	var email: String?
	
	/// The user's shipping address.
	var shippingAddress: String?
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case name
		case phoneNumber = "phone_number"
		case email
		case shippingAddress = "shipping_address"
	}
	
	
}
