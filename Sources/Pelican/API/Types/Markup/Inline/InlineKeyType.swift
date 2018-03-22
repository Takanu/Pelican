//
//  InlineKeyType.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation

/**
Defines what type of function a InlineButtonKey has.
*/
public enum InlineKeyType: String {
	
	/// HTTP url to be opened by the client when button is pressed.
	case url
	
	/// Data to be sent in a callback query to the bot when button is pressed, 1-64 bytes
	case callbackData
	
	/// Prompts the user to select one of their chats, open it and insert the bot‘s username and the specified query in the input field.
	case switchInlineQuery
	
	/// If set, pressing the button will insert the bot‘s username and the specified inline query in the current chat's input field.  Can be empty.
	case switchInlineQuery_currentChat
	
	/**
	Description of the game that will be launched when the user presses the button.
	- note: This type of button must always be the first button in the first row.
	*/
	case callbackGame
	
	/**
	Specify True, to send a Pay button.
	- note: This type of button must always be the first button in the first row.
	*/
	case payButton
	
	/**
	If this type is defined, Pelican was unable to infer what type the received InlineKey was, either due to a bug, a bad response or a change in the Telegram API that Pelican doesn't yet support.
	*/
	case unknown
}
