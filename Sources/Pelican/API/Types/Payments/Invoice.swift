//
//  Invoice.swift
//  Pelican
//
//  Created by Ido Constantine on 18/12/2017.
//

import Foundation
import Vapor
import FluentProvider

/**
Contains basic information about an invoice for the Telegram Payment API.
*/
public class Invoice: Codable {
	
	/// Product name.
	var title: String = ""
	
	/// Product description.
	var description: String = ""
	
	/// A unique bot deep-linking parameter that can be used to generate this invoice.
	var startParameter: String = ""
	
	/// Three-letter [ISO 4217 currency code](https://core.telegram.org/bots/payments#supported-currencies).
	var currency: String = ""
	
	/**
	Total price in the smallest units of the currency.  For example, for a price of US$ 1.45 pass amount = 145.
	
	See the exp parameter in [currencies.json](https://core.telegram.org/bots/payments/currencies.json) for more information, it shows the number of digits past the decimal point for each currency (2 for the majority of currencies).
	*/
	var totalAmount: Int = 0
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case title
		case description
		case startParameter = "start_parameter"
		case currency
		case totalAmount = "total_amount"
	}
	
	
}
