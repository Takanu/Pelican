//
//  Request.swift
//  Pelican
//
//  Created by Takanu Kyriako on 16/12/2017.
//

import Foundation

/**
A delegate for creating and sending TelegramRequest types.

Use this in your sessions to make requests to Telegram like sending messages or getting chat information.
The delegate will attempt to process the response received from Telegram into a useful and context-sensitive type.

- To make synchronous calls where your code execution will wait until a response from Telegram is received, use the `sync` property.
- To make asynchronous calls where your code execution will continue immediately after the request is made and sent, use the `async` property.

- note: Due to the unpredictability of networking, server up-time and maintenance there is always a chance that a request
may not succeed.  Make sure to account for this when writing your own bots.
*/
public struct SessionRequest {
	
	/// The tag of the session that this request instance belongs to.
	var tag: SessionTag
	
	/// Contains all API methods you can use to make a synchronous API request, where your code execution will wait until a response from Telegram is received.
	var sync: SessionRequestSync
	
	/// Contains all API methods you can use to make an asynchronous API request, where your code execution will continue immediately after the request is made and sent.
	var async: SessionRequestAsync
	
	public init(tag: SessionTag) {
		self.tag = tag
		self.sync = SessionRequestSync(tag: tag)
		self.async = SessionRequestAsync(tag: tag)
	}
}