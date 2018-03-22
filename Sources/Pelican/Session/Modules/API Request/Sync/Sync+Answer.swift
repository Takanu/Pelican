//
//  SessionRequest+Answer.swift
//  Pelican
//
//  Created by Takanu Kyriako on 17/12/2017.
//

import Foundation

extension SessionRequestSync {
	
	/**
	???
	*/
	public func answerCallbackQuery(queryID: String,
																	text: String?,
																	showAlert: Bool,
																	url: String = "",
																	cacheTime: Int = 0) {
		
		let request = TelegramRequest.answerCallbackQuery(queryID: queryID, text: text, showAlert: showAlert, url: url, cacheTime: cacheTime)
		_ = tag.sendSyncRequest(request)
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
																switchPMParam: String?) {
		
		let request = TelegramRequest.answerInlineQuery(queryID: queryID, results: results, cacheTime: cacheTime, isPersonal: isPersonal, nextOffset: nextOffset, switchPM: switchPM, switchPMParam: switchPMParam)
		if request != nil {
			_ = tag.sendSyncRequest(request!)
		}
	}
}
