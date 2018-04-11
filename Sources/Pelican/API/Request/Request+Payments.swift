//
//  Request+Payments.swift
//  Pelican
//
//  Created by Takanu Kyriako on 18/12/2017.
//

import Foundation

extension TelegramRequest {
	
	/**
	NOT YET FINISHED ! ! !
	Use this method to send invoices.
	- parameter prices: An array of costs involved in the transaction (eg. product price, taxes, discounts).
	*/
	static public func sendInvoice(title: String,
																 description: String,
																 payload: String,
																 providerToken: String,
																 startParameter: String,
																 currency: String,
																 prices: [String: Int],
																 chatID: String) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"title": title,
			"description": description,
			"payload": payload,
			"provider_token": providerToken,
			"start_parameter": startParameter,
			"currency": currency,
			"prices": prices,
			"chat_id": Int(chatID)
		]
		
		// Set the query
		request.method = "sendInvoice"
		
		return request
	}
	
	/**
	NOT YET FINISHED ! ! !
	If you sent an invoice requesting a shipping address and the parameter is_flexible was specified, the Bot API will send an Update with a shipping_query field to the bot.
	Use this method to reply to shipping queries. On success, True is returned.
	*/
	static public func answerShippingQuery(shippingQueryID: String,
																				 acceptShippingAddress: Bool,
																				 shippingOptionsFIXME: [String]?,
																				 errorMessage: String?) -> TelegramRequest {
		
		let request = TelegramRequest()
		
		request.query = [
			"shipping_query_id": shippingQueryID,
			"ok": acceptShippingAddress,
			"shipping_options": shippingOptionsFIXME,
		]
		
		if errorMessage != nil { request.query["error_message"] = errorMessage }
		
		// Set the query
		request.method = "answerShippingQuery"
		
		return request
	}
	
	/**
	Once the user has confirmed their payment and shipping details, the Bot API sends the final confirmation in the form of an Update with the field pre_checkout_query. Use this method to respond to such pre-checkout queries. On success, True is returned.
	
	- note: The Bot API must receive an answer within 10 seconds after the pre-checkout query was sent.
	*/
	static public func answerPreCheckoutQuery(preCheckoutQueryID: String,
																						acceptPaymentQuery: Bool,
																						errorMessage: String?) -> TelegramRequest {
		let request = TelegramRequest()
		
		request.query = [
			"pre_checkout_query_id": preCheckoutQueryID,
			"ok": acceptPaymentQuery,
		]
		
		if errorMessage != nil { request.query["error_message"] = errorMessage }
		
		// Set the query
		request.method = "answerPreCheckoutQuery"
		
		return request
	}
	
}
