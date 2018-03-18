//
//  SessionRequestAsync+Send.swift
//  Pelican
//
//  Created by Ido Constantine on 18/03/2018.
//

import Foundation

extension SessionRequestAsync {
	
	/**
	Sends a text-based message to the chat linked to this session.
	*/
	public func sendMessage(_ message: String,
													markup: MarkupType?,
													chatID: Int,
													parseMode: MessageParseMode = .markdown,
													replyID: Int = 0,
													useWebPreview: Bool = false,
													disableNotification: Bool = false,
													callback: ((Message?) -> ())?) {
		
		let request = TelegramRequest.sendMessage(chatID: chatID, text: message, markup: markup, parseMode: parseMode, disableWebPreview: useWebPreview, disableNotification: disableNotification, replyMessageID: replyID)
		let response = tag.sendAsyncRequest(request) { response in
			
		}
		
	}
	
}
