//
//  InlineResultContact.swift
//  Pelican
//
//  Created by Ido Constantine on 20/12/2017.
//

import Foundation

/**
Represents a contact with a phone number.

By default, this contact will be sent by the user.  Alternatively, you can use the `content` property to send a message with the specified content instead of the file.
*/
public struct InlineResultContact: InlineResult {
	
	/// Type of the result being given.
	public var type: String = "contact"
	
	/// Unique identifier for the result, 1-64 bytes.
	public var id: String
	
	/// Content of the message to be sent.
	public var content: InputMessageContent?
	
	/// Inline keyboard attached to the message
	public var markup: MarkupInline?
	
	
	/// Contact's phone number.
	public var phoneNumber: String
	
	/// Contact's first name.
	public var firstName: String
	
	///  Contact's last name.
	public var lastName: String?
	
	
	/// URL of the thumbnail to use for the result.
	public var thumbURL: String?
	
	/// Thumbnail width.
	public var thumbWidth: Int?
	
	/// Thumbnail height.
	public var thumbHeight: Int?
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case type
		case id
		case content = "input_message_content"
		case markup = "reply_markup"
		
		case phoneNumber = "phone_number"
		case firstName = "first_name"
		case lastName = "last_name"
		
		case thumbURL = "thumb_url"
		case thumbWidth = "thumb_width"
		case thumbHeight = "thumb_height"
	}
	
	init(id: String, phoneNumber: String, firstName: String, lastName: String?, content: InputMessageContent?) {
		self.id = id
		self.phoneNumber = phoneNumber
		self.firstName = firstName
		self.lastName = lastName
		self.content = content
	}
	
}
