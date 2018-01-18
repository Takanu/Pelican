//
//  InlineResultArticle.swift
//  Pelican
//
//  Created by Ido Constantine on 19/12/2017.
//

import Foundation

/**
Represents a link to an article or web page.  This type is also ideal for setting the contents to a simple message by using the `content` property, for sending messages to a chat.
*/
final public class InlineResultArticle: InlineResult {
	
	/// Type of the result being given.
	public var type: String = "article"
	
	/// Unique Identifier for the result, 1-64 bytes.
	public var tgID: String
	
	/// Content of the message to be sent.
	public var content: InputMessageContent?
	
	/// Inline keyboard attached to the message
	public var replyMarkup: MarkupInline?
	
	
	/// URL of the result.
	public var url: String?
	
	/// The title of the inline result.
	public var title: String
	
	/// The description of the inline result.
	public var description: String?
	
	/// Set as true if you don't want the URL to be shown in the message.
	public var hideURL: Bool?
	
	
	/// URL of the thumbnailnail to use for the result.
	public var thumbnailURL: String?
	
	/// Thumbnail width.
	public var thumbnailWidth: Int?
	
	/// Thumbnail height.
	public var thumbnailHeight: Int?
	
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case type
		case tgID = "id"
		case content = "input_message_content"
		case replyMarkup = "reply_markup"
		
		case url
		case title
		case description
		case hideURL = "hide_url"
		
		case thumbnailURL = "thumb_url"
		case thumbnailWidth = "thumb_width"
		case thumbnailHeight = "thumb_height"
	}
	
	/**
	Initialises a InlineResultArticle type for the explicit purpose of sending a text message, rather than a link.
	*/
	public init(id: String, title: String, description: String, contents: String, markup: MarkupInline?) {
		self.tgID = id
		self.title = title
		self.content = InputMessageContent(content: InputMessageContent_Text(text: contents,
																																				 parseMode: "",
																																				 disableWebPreview: nil
		))
		
		self.replyMarkup = markup
		self.description = description
	}
	
	/**
	Initialises an InlineResultArticle type to provide a link to an article or web page.
	*/
	public init(id: String,
							title: String,
							description: String,
							url: String,
							markup: MarkupInline?,
							hideURL: Bool?,
							thumbnailURL: String?,
							thumbnailWidth: Int?,
							thumbnailHeight: Int?) {
		
		self.tgID = id
		self.content = nil
		self.title = title
		self.description = description
		self.replyMarkup = markup
		self.url = url
		
		self.hideURL = hideURL
		self.thumbnailURL = thumbnailURL
		self.thumbnailWidth = thumbnailWidth
		self.thumbnailHeight = thumbnailHeight
	}
}
