//
//  Answer.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation
import Vapor

/**
A delegate for a session, to send requests to Telegram that correspond with sending chat messages.

One of a collection of delegates used to let Sessions make requests to Telegram in a language and format
thats concise, descriptive and direct.
*/
public class TGAnswer {
	
	var tag: SessionTag
	
	init(tag: SessionTag) {
		self.tag = tag
	}
	
	/**
	???
	*/
	public func callbackQuery(queryID: String, text: String?, showAlert: Bool, url: String = "", cacheTime: Int = 0) {
		
		let request = TelegramRequest.answerCallbackQuery(queryID: queryID, text: text, showAlert: showAlert, url: url, cacheTime: cacheTime)
		_ = tag.sendRequest(request)
	}
	
	/**
	???
	*/
	public func inlineQuery(queryID: Int, results: [InlineResult], cacheTime: Int = 0, isPersonal: Bool = false, nextOffset: String?, switchPM: String?, switchPMParam: String?) {
		
		let request = TelegramRequest.answerInlineQuery(queryID: queryID, results: results, cacheTime: cacheTime, isPersonal: isPersonal, nextOffset: nextOffset, switchPM: switchPM, switchPMParam: switchPMParam)
		_ = tag.sendRequest(request)
	}
}

