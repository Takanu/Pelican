//
//  File.swift
//  Pelican
//
//  Created by Takanu Kyriako on 18/12/2017.
//

import Foundation


/**
Contains information about an incoming pre-checked query for the Telegram Payment API.
*/
public struct PreCheckoutQuery: Codable, UpdateModel {
	
	/// A unique query identifier.
	var id: String = ""
	
	/// The user who sent the query.
	var from: User = User(id: "0", isBot: false, firstName: "fixme")
	
	/// Three-letter [ISO 4217 currency code](https://core.telegram.org/bots/payments#supported-currencies).
	var currency: String = ""
	
	/**
	Total price in the smallest units of the currency.  For example, for a price of US$ 1.45 pass amount = 145.
	
	See the exp parameter in [currencies.json](https://core.telegram.org/bots/payments/currencies.json) for more information, it shows the number of digits past the decimal point for each currency (2 for the majority of currencies).
	*/
	var totalAmount: Int = 0
	
	/// The bot-specified invoice payload.
	var invoicePayload: String = ""
	
	/// The identifier of the shipping option chosen by the user.
	var shippingOptionID: String?
	
	/// Order information provided by the user.
	var orderInfo: OrderInfo?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case id
		case from
		case currency
		case totalAmount = "total_amount"
		case invoicePayload = "invoice_payload"
		case shippingOptionID = "shipping_option_id"
		case orderInfo = "order_info"
	}
	
}
