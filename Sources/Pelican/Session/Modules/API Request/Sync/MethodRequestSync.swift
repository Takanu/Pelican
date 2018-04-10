//
//  MethodRequestync.swift
//  Pelican
//
//  Created by Ido Constantine on 18/03/2018.
//

import Foundation

/**
A delegate for creating and sending TelegramRequest types in a synchronous manner,
where your code execution will wait until a response from Telegram is received.

Useful if an event requires a result from Telegram like receiving the result of a sent message, if your code
needs to do something with it immediately afterwards.

- note: If you only need to make a request to Telegram and can either deal with the result later or don't need to know the results,
use the `async` property that can be found in `MethodRequest`, as it will improve the responsiveness and performance of
your app.
*/
public struct MethodRequestSync {
	
	/// The tag of the session that this request instance belongs to.
	var tag: SessionTag
	
	public init(tag: SessionTag) {
		self.tag = tag
	}
	
	/**
	Allows you to make a custom request to Telegram, using a method name and set of arguments as a dictionary.
	
	Use this if Pelican hasn't yet implemented a new API method, but also submit an issue [right about here](https://github.com/Takanu/Pelican)
	here so I can add it 👌👍.
	*/
	func customRequest(methodName: String, queries: [String: Codable]) -> TelegramResponse? {
		
		return nil
	}
}
