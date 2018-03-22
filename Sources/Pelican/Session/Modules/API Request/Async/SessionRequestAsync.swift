//
//  SessionRequestAsync.swift
//  Pelican
//
//  Created by Ido Constantine on 18/03/2018.
//

import Foundation

/**
A delegate for creating and sending TelegramRequest types in a synchronous manner,
where your code execution will continue immediately after the request is made and sent.

Use this if you don't need to handle the response immediately after making the request or don't need to know
the result of a request.
*/
public struct SessionRequestAsync {
	
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
	func customRequest(methodName: String, queries: [String: Codable], file: MessageFile?, callback: ((TelegramResponse?) -> ())? ) {
		
		let request = TelegramRequest()
		request.method = methodName
		request.query = queries
		request.file = file
		
		tag.sendAsyncRequest(request) { response in
			if callback != nil {
				callback!(response)
			}
		}
		
		
	}
}
