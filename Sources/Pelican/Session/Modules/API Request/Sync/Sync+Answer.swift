//
//  MethodRequest+Answer.swift
//  Pelican
//
//  Created by Takanu Kyriako on 17/12/2017.
//

import Foundation

extension MethodRequestAsync {
	
	/**
	???
	*/
	@discardableResult
	public func answerCallbackQuery(queryID: String,
																	text: String?,
																	showAlert: Bool,
																	url: String = "",
																	cacheTime: Int = 0) -> Bool {
		
		let request = TelegramRequest.answerCallbackQuery(queryID: queryID, text: text, showAlert: showAlert, url: url, cacheTime: cacheTime)
		let response = tag.sendSyncRequest(request)
		return MethodRequest.decodeResponse(response) ?? false
	}
	
	/**
	???
	*/
	@discardableResult
	public func answerInlineQuery(queryID: String,
																results: [InlineResult],
																cacheTime: Int = 0,
																isPersonal: Bool = false,
																nextOffset: String?,
																switchPM: String?,
																switchPMParam: String?)  -> Bool {
		
		let request = TelegramRequest.answerInlineQuery(queryID: queryID,
																										results: results,
																										cacheTime: cacheTime,
																										isPersonal: isPersonal,
																										nextOffset: nextOffset,
																										switchPM: switchPM,
																										switchPMParam: switchPMParam)
		
		if request != nil {
			let response = tag.sendSyncRequest(request!)
			return MethodRequest.decodeResponse(response) ?? false
		}
		
		return false
	}
}
