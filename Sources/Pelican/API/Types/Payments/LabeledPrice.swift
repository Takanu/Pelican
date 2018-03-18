//
//  LabeledPrice.swift
//  Pelican
//
//  Created by Takanu Kyriako on 19/12/2017.
//

import Foundation


/**
Represents a portion of the price for goods and services being sold (eg. item, discounts, taxes, shipping).
*/
public struct LabeledPrice: Codable {
	
	/// The name of the portion.
	var label: String
	
	/**
	The price of the portion in the smallest units of the currency.  For example, for a price of US$ 1.45 pass amount = 145.
	
	See the exp parameter in [currencies.json](https://core.telegram.org/bots/payments/currencies.json) for more information, it shows the number of digits past the decimal point for each currency (2 for the majority of currencies).
	*/
	var amount: Int
	
}
