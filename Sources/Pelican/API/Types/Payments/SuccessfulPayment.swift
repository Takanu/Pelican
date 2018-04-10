//
//  SuccessfulPayment.swift
//  Pelican
//
//  Created by Takanu Kyriako on 18/12/2017.
//

import Foundation


/**
Contains basic information about a successful payment for the Telegram Payment API.
*/
public struct SuccessfulPayment: Codable {
	
	/// Three-letter [ISO 4217 currency code](https://core.telegram.org/bots/payments#supported-currencies).
	var currency: String = ""
	
	/**
	Total price in the smallest units of the currency.  For example, for a price of US$ 1.45 pass amount = 145.
	
	See the exp parameter in [currencies.json](https://core.telegram.org/bots/payments/currencies.json) for more information, it shows the number of digits past the decimal point for each currency (2 for the majority of currencies).
	*/
	var totalAmount: Int = 0
	
	/// The bot-specified invoice payload.
	var invoicePayload: String = ""
	
	/// The identifier of the shipping option chosen by the user, if applicable.
	var shippingOptionID: String?
	
	/// The order information provided by the user, if applicable.
	var orderInfo: OrderInfo?
	
	/// Telegram's payment identifier for the payment.
	var telegramPaymentChargeID: String = ""
	
	/// The external payment identifier for the payment, determined by the provider chosen.
	var providerPaymentChargeID: String = ""
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case currency
		case totalAmount = "total_amount"
		case invoicePayload = "invoice_payload"
		case shippingOptionID = "shipping_option_id"
		case orderInfo = "order_info"
		case telegramPaymentChargeID = "telegram_payment_charge_id"
		case providerPaymentChargeID = "provider_payment_charge_id"
	}
	
}
