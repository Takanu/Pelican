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
	
	/// This defines the update as an incoming message of any kind.
	case message
	/// This defines the update as a new version of a message that is known to the bot and was edited.
	case editedMessage
	/// This defines the update as an incoming channel post of any kind.
	case channelPost
	/// This defines the update as a new version of a channel post that is known to the bot and was edited.
	case editedChannelPost
	
	/// This defines the update as a new incoming callback query.
	case callbackQuery
	/// This defines the update as a new incoming inline query.
	case inlineQuery
	/// This defines the update as the result of an inline query that was chosen by a user and sent to their chat partner.
	case chosenInlineResult
	/// This defines the update as a new incoming shipping query.
	case shippingQuery
	/// This defines the update as a new incoming pre-checkout query. Contains full information from the checkout.
	case preCheckoutQuery
	
	public func string() -> String {
		return rawValue
	}
}
