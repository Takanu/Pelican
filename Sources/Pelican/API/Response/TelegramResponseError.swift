//
//  File.swift
//  PelicanPackageDescription
//
//  Created by Ido Constantine on 19/01/2018.
//

import Foundation


/// I might use this later, but currently I have no need to manually define many kinds of errors.
/*
class TelegramResponseError {
	
	/// The error code given by Telegram.  This error code is not unique.
	var internalErrorCode: Int
	/// The error code given by Pelican to ensure errors are uniquely defined.
	var pelicanErrorCode: String
	/// A description of the error given by Telegram.
	var description: String
	
	init(telegramCode: Int, pelicanCode: String, description: String) {
		self.internalErrorCode = telegramCode
		self.pelicanErrorCode = pelicanCode
		self.description = description
	}
	
}

extension TelegramResponse {
	/**
	Defines a collection of generic Telegram Request errors that can be received.
	
	* This is not a complete list.
	* Error codes and descriptions can change at any time, and the ones stated here may become outdated at any time.
	*/
	static var errorList: [TelegramResponseError] = [
		TelegramResponseError(telegramCode: 400, pelicanCode: "400-A", description: "Bad Request"),
		TelegramResponseError(telegramCode: 401, pelicanCode: "400-A", description: "Unauthorised"),
		TelegramResponseError(telegramCode: 402, pelicanCode: "400-A", description: "Unautorised"),
		TelegramResponseError(telegramCode: 403, pelicanCode: "400-A", description: "Unautorised"),
		TelegramResponseError(telegramCode: 401, pelicanCode: "400-A", description: "Unautorised"),
	
	
	
	]
	
}
*/
