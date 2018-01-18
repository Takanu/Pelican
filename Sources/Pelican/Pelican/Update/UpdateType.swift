//
//  UpdateType.swift
//  Pelican
//
//  Created by Takanu Kyriako on 21/08/2017.
//

import Foundation


/**
Categorises the types of requests that can be made by a user to the bot.
*/
public enum UpdateType: String, CasedEnum {
	
	case message
	case callbackQuery
	case inlineQuery
	case chosenInlineResult
	case shippingQuery
	case preCheckoutQuery
	
	public func string() -> String {
		return rawValue
	}
}
