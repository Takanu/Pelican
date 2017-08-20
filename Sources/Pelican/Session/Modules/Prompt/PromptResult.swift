//
//  PromptResult.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation

/** Defines a single prompt result.  Can be used to define who last pressed a button
as well as what button was the "winner".
*/
public struct PromptResult {
	public var users: [User] = []
	public var key: MarkupInlineKey
	
	init(users: [User], key: MarkupInlineKey) {
		self.users = users
		self.key = key
	}
}
