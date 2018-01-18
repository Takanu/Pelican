


/**
Defines anything relating to types, but isn't a real type component, such as protocols and extensions.
*/


import Foundation
import Vapor
import FluentProvider

/**
For any model that replicates the Telegram API, it must inherit fron this to be designed to build queries and be converted from responses
in a way that Telegram understands.
*/
protocol TelegramType {
	
}




// All types that conform to this protocol are able to convert itself into a aet of query information
protocol TelegramQuery: NodeConvertible, JSONConvertible {
  func makeQuerySet() -> [String:NodeConvertible]
}

// Defines a type that can send unique content types inside a message.
public protocol MessageContent: Codable {
	
	/// What API type the type that uses this protocol is imitating.
	var contentType: String { get }
	
	/// The method used when the Telegram API call is made.
  var method: String { get }
	
	/// Used to enable any method sending this message content to access the information it needs to deliver it, omitting any custom properties.
  func getQuery() -> [String:NodeConvertible]
}



/**
Defines a type of Message content that is represented by a fileID (in which case the content has been uploaded before),
and/or a URL (the location of the resource to be uploaded).

All types that conform to this protocol should also provide initialisers that accept a URL instead of a fileID
*/
public protocol MessageFile: MessageContent {
	
	/// The content type it represents, used by Telegram to interpret what is being sent.
	var contentType: String { get }
	
	/// The method that will be used to send this content type.
	var method: String { get }
	
	/// The Telegram File ID, obtained when a file is uploaded to the bot either by the bot itself, or by a user interacting with it.
	var fileID: String? { get set }
	/**
	The path to the resource either as a local source relative to the Public/ folder
	of your app (eg. `karaoke/jack-1.png`) or as a remote source using an HTTP link.
	*/
	var url: String? { get set }
}

extension MessageFile {
	
	/// Returns whether or not the object has the necessary requirements to be sent.
	var isSendable: Bool {
		if fileID == nil && url == nil {
			return false
		}
		return true
	}
}



/**
Defines a type that encapsulates a request from a user, through a standard Telegram API type (eg.  Message, InlineQuery, CallbackQuery).
*/
public protocol UpdateModel: Codable {
	
	
}


