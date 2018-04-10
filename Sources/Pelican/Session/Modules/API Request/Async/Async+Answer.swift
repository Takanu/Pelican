//
//  Async+Answer.swift
//  Pelican
//
//  Created by Ido Constantine on 26/03/2018.
//

import Foundation

extension MethodRequestAsync {
	
	/**
	???
	*/
	public func answerCallbackQuery(queryID: String,
																	text: String?,
																	showAlert: Bool,
																	url: String = "",
																	cacheTime: Int = 0,
																	callback: CallbackBoolean = nil) {
		
		let request = TelegramRequest.answerCallbackQuery(queryID: queryID, text: text, showAlert: showAlert, url: url, cacheTime: cacheTime)
		tag.sendAsyncRequest(request) { response in
			
			if callback != nil {
				callback!(MethodRequest.decodeResponse(response) ?? false)
			}
		}
	}
	
	/**
	???
	*/
	public func answerInlineQuery(queryID: String,
																results: [InlineResult],
																cacheTime: Int = 0,
																isPersonal: Bool = false,
																nextOffset: String?,
																switchPM: String?,
																switchPMParam: String?,
																callback: CallbackBoolean = nil) {
		
		let request = TelegramRequest.answerInlineQuery(queryID: queryID, results: results, cacheTime: cacheTime, isPersonal: isPersonal, nextOffset: nextOffset, switchPM: switchPM, switchPMParam: switchPMParam)
		
		if request != nil {
			tag.sendAsyncRequest(request!) { response in
				
				if callback != nil {
					callback!(MethodRequest.decodeResponse(response) ?? false)
					return
				}
			}
		}
		
		if callback != nil {
			callback!(false)
		}
	}
	
}
