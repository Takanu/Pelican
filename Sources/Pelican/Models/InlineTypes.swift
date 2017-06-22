
import Foundation
import Vapor
import FluentProvider

/** Represents an incoming inline query. When the user sends an empty query, your bot could return some default or trending results.
 */
final public class InlineQuery: Model, UserRequest {
	public var storage = Storage()
	
  public var id: String // Unique identifier for this query.
  public var from: User // The sender.
  public var query: String // Text of the query (up to 512 characters).
  public var offset: String // Offset of the results to be returned, is bot-controllable.
  public var location: Location? // Sender location, only for bots that request it.
  
  // Model conforming methods
  public required init(row: Row) throws {
    id = try row.get("id")
		from = try User(row: try row.get("from"))
		query = try row.get("query")
		offset = try row.get("offset")
		if let locationSub = row["location"] {
			location = try Location(row: locationSub)
		}
  }
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("id", id)
		try row.set("from", from)
		try row.set("query", query)
		try row.set("offset", offset)
		try row.set("location", location)
		
		return row
	}
}


/** Represents a result of an inline query that was chosen by the user and sent to their chat partner. 
 */
public struct ChosenInlineResult: UserRequest {
	public var storage = Storage()
	
  var resultID: String // The unique identifier for the result that was chosen.
  var from: User // The user that chose the result.
  var query: String // The query that was used to obtain the result
  var location: Location? // Sender location, only for bots that require user location.
  var inlineMessageID: String? // Identifier of the sent inline message. Available only if there is an inline keyboard attached to the message.
  
	// Model conforming methods
	public init(row: Row) throws {
		resultID = try row.get("result_id")
		from = try User(row: try row.get("from"))
		query = try row.get("query")
		if let locationSub = row["location"] {
			location = try Location(row: locationSub)
		}
		inlineMessageID = try row.get("inline_message_id")
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("result_id", resultID)
		try row.set("from", from)
		try row.set("query", query)
		try row.set("location", location)
		try row.set("inline_message_id", location)
		
		return row
	}
}



/** Used for a result/your response of an inline query.
 */
public protocol InlineResult: Model {
  
}

final public class InlineResultArticle: InlineResult {
	public var storage = Storage()
	
  public var type: String = "article"        // Type of the result being given.
  public var tgID: String                    // Unique Identifier for the result, 1-64 bytes.
  public var content: InputMessageContent    // Content of the message to be sent.
  public var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
  
  public var title: String                   // TItle of the result.
  public var url: String?                    // URL of the result.
  public var hideUrl: Bool?                  // Set as true if you don't want the URL to be shown in the message.
  public var description: String?            // Short description of the result.
  //var thumb: InlineThumbnail?							 // Inline thumbnail type.
	
  
  public init(id: String, title: String, description: String, contents: String, markup: MarkupInline?) {
		self.tgID = id
    self.title = title
    self.content = InputMessageText(text: contents, parseMode: "", disableWebPreview: nil)
    self.replyMarkup = markup
    self.description = description
  }
  
  // NodeRepresentable conforming methods
  public init(row: Row) throws {
    type = try row.get("type")
    tgID = try row.get("id")
		content = try row.get("input_message_content")
		replyMarkup = try row.get("reply_markup")
		
		title = try row.get("title")
		url = try row.get("url")
		hideUrl = try row.get("hide_url")
		description = try row.get("description")
		//thumb = try row.get("thumb")
  }
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("type", type)
		try row.set("id", tgID)
		try row.set("input_message_content", content)
		try row.set("reply_markup", replyMarkup)
		
		try row.set("title", title)
		try row.set("url", url)
		try row.set("hide_url", hideUrl)
		try row.set("description", description)
		//try row.set("thumb", thumb)
		
		return row
	}
}
/**

public struct InlineResultContact: InlineResult {
	public var storage = Storage()
	
  public var type: String = "contact"        // Type of the result being given.
  public var id: String                      // Unique Identifier for the result, 1-64 bytes.
  public var content: InputMessageContent?   // Content of the message to be sent.
  public var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
  
  public var phoneNumber: String             // Contact's phone number.
  public var firstName: String               // Contact's first name.
  public var lastName: String?               //  Contact's last name.
  var thumb: InlineThumbnail?         // Inline thumbnail type.
  
  // NodeRepresentable conforming methods
  public init(row: Row) throws {
    type = try row.get("type")
    id = try row.get("id")
    
    if let subContent = node["input_message_content"] {
      self.content = try .init(node: subContent, in: context) as InputMessageContent }
    
    replyMarkup = try row.get("reply_markup")
    
    // Non-core extractions
    phoneNumber = try row.get("phone_number")
    firstName = try row.get("first_name")
    lastName = try row.get("last_name")
    thumb = try InlineThumbnail(node: node, in: TGContext.response)
    
  }
  
  public func makeNode() throws -> Node {
    var keys: [String:NodeRepresentable] = [
      "type": type,
      "id": id,
      "phone_number": phoneNumber,
      "first_name": firstName]
    
    // Optional keys
    if content != nil { keys["input_message_content"] = content }
    if replyMarkup != nil { keys["reply_markup"] = replyMarkup }
    if lastName != nil { keys["input_message_content"] = lastName }
    //if thumb != nil { keys["reply_markup"] = thumb }
    
    return try Node(node: keys)
  }
  
  public func makeNode(context: Context) throws -> Node {
    return try self.makeNode()
  }
}


public struct InlineResultLocation: InlineResult {
  var type: String = "location"       // Type of the result being given.
  public var id: String                      // Unique Identifier for the result, 1-64 bytes.
  public var content: InputMessageContent?   // Content of the message to be sent.
  public var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
  
  public var title: String                   // Location title.
  public var latitude: Float                 // Location latitude in degrees.
  public var longitude: Float                // Location longitude in degrees.
  var thumb: InlineThumbnail?         // Inline thumbnail type.
  
  // NodeRepresentable conforming methods
  public init(row: Row) throws {
    type = try row.get("type")
    id = try row.get("id")
    
    if let subContent = node["input_message_content"] {
      self.content = try .init(node: subContent, in: context) as InputMessageContent }
    
    replyMarkup = try row.get("reply_markup")
    
    // Non-core extractions
    title = try row.get("title")
    latitude = try row.get("latitude")
    longitude = try row.get("longitude")
    thumb = try InlineThumbnail(node: node, in: TGContext.response)
  }
  
  public func makeNode() throws -> Node {
    var keys: [String:NodeRepresentable] = [
      "type": type,
      "id": id,
      "title": title,
      "latitude": latitude,
      "longitude": longitude]
    
    // Optional keys
    if content != nil { keys["input_message_content"] = content }
    if replyMarkup != nil { keys["reply_markup"] = replyMarkup }
    //if thumb != nil { keys["reply_markup"] = thumb }
    
    return try Node(node: keys)
  }
  
  public func makeNode(context: Context) throws -> Node {
    return try self.makeNode()
  }
}

public struct InlineResultVenue: InlineResult {
  var type: String = "venue"          // Type of the result being given.
  public var id: String                      // Unique Identifier for the result, 1-64 bytes.
  public var content: InputMessageContent?   // Content of the message to be sent.
  public var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
  
  public var title: String                   // Location title.
  public var address: String                 // Address of the venue.
  public var latitude: Float                 // Location latitude in degrees.
  public var longitude: Float                // Location longitude in degrees.
  public var foursquareID: String?           // Foursquare identifier of the venue if know.
  var thumb: InlineThumbnail?         // Inline thumbnail type.
  
  // NodeRepresentable conforming methods
  public init(row: Row) throws {
    type = try row.get("type")
    id = try row.get("id")
    
    if let subContent = node["input_message_content"] {
      self.content = try .init(node: subContent, in: context) as InputMessageContent }
    
    replyMarkup = try row.get("reply_markup")
    
    // Non-core extractions
    title = try row.get("title")
    address = try row.get("address")
    latitude = try row.get("latitude")
    longitude = try row.get("longitude")
    foursquareID = try row.get("foursquare_id")
    thumb = try InlineThumbnail(node: node, in: TGContext.response)
    
  }
  
  public func makeNode() throws -> Node {
    var keys: [String:NodeRepresentable] = [
      "type": type,
      "id": id,
      "title": title,
      "address": address,
      "latitude": latitude,
      "longitude": longitude]
    
    // Optional keys
    if content != nil { keys["input_message_content"] = content }
    if replyMarkup != nil { keys["reply_markup"] = replyMarkup }
    if foursquareID != nil { keys["foursquare_id"] = foursquareID }
    //if thumb != nil { keys["reply_markup"] = thumb }
    
    return try Node(node: keys)
  }
  
  public func makeNode(context: Context) throws -> Node {
    return try self.makeNode()
  }
}

public struct InlineResultGame: InlineResult {
  var type: String = "game"           // Type of the result being given.
  public var id: String                      // Unique Identifier for the result, 1-64 bytes.
  public var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
  public var name: String                    // Short name of the game
  
  // NodeRepresentable conforming methods
  public init(row: Row) throws {
    type = try row.get("type")
    id = try row.get("id")
    replyMarkup = try row.get("reply_markup")
    name = try row.get("game_short_name")
    
  }
  
  public func makeNode() throws -> Node {
    var keys: [String:NodeRepresentable] = [
      "type": type,
      "id": id,
      "game_short_name": name]
    
    // Optional keys
    if replyMarkup != nil { keys["reply_markup"] = replyMarkup }
    return try Node(node: keys)
  }
  
  public func makeNode(context: Context) throws -> Node {
    return try self.makeNode()
  }
}



enum InlineResultError: String, Error {
  case idNotFound = "ID not found during node initialisation."
  
}



 // makeNode() currently makes no effort to divide content based on whether it's cached or not.
 // Use getQuery() instead.
 
 /** Represents either a link to a MP3 audio file stored on the Telegram servers, or an external URL link to one. */
 struct InlineResultAudio: InlineResult {
 var type: String = "audio"          // Type of the result being given.
 var id: String                      // Unique Identifier for the result, 1-64 bytes.
 var content: InputMessageContent?   // Content of the message to be sent.
 var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
 
 var url: String // Identifier/URL depending on the above.
 var caption: String? // Caption, 0-200 characters.
 
 // Non-cached types
 var title: String? // Title.
 var performer: String?  // Performer.
 var duration: Int? // Audio duration in seconds.
 
 // NodeRepresentable conforming methods
 init(node: Node, in context: Context) throws {
 type = try row.get("file_id")
 id = try row.get("duration")
 if let subContent = node["input_message_content"] {
 self.content = try .init(node: subContent, in: context) as InputMessageContent }
 replyMarkup = try row.get("reply_markup")
 
 }
 
 func makeNode() throws -> Node {
 var keys: [String:NodeRepresentable] = [
 "type": type,
 "id": id]
 
 // Optional keys
 if content != nil { keys["input_message_content"] = content }
 if replyMarkup != nil { keys["reply_markup"] = replyMarkup }
 
 return try Node(node: keys)
 }
 
 func makeNode(context: Context) throws -> Node {
 return try self.makeNode()
 }
 }
 
 /** Represents either a link to a file stored on the Telegram servers, or an external URL link to one.  If sent using an external link, only .PDF and .ZIP files are supported. */
 struct InlineResultDocument: InlineResult {
 var type: String = "document"       // Type of the result being given.
 var id: String                      // Unique Identifier for the result, 1-64 bytes.
 var content: InputMessageContent?   // Content of the message to be sent.
 var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
 
 var url: String // Identifier/URL depending on the above.
 var title: String // Title.
 var caption: String? // Caption, 0-200 characters.
 var description: String? // Short description of the result.
 
 // Non-cached types
 var mimeType: String? // Mime type of the content of the file, either “application/pdf” or “application/zip”.  Not optional for un-cached.
 var thumb: InlineThumbnail? // URL of the thumbbail for the result (JPEG only)
 
 // NodeRepresentable conforming methods
 init(node: Node, in context: Context) throws {
 type = try row.get("file_id")
 id = try row.get("duration")
 if let subContent = node["input_message_content"] {
 self.content = try .init(node: subContent, in: context) as InputMessageContent }
 replyMarkup = try row.get("reply_markup")
 
 }
 
 func makeNode() throws -> Node {
 var keys: [String:NodeRepresentable] = [
 "type": type,
 "id": id]
 
 // Optional keys
 if content != nil { keys["input_message_content"] = content }
 if replyMarkup != nil { keys["reply_markup"] = replyMarkup }
 
 return try Node(node: keys)
 }
 
 func makeNode(context: Context) throws -> Node {
 return try self.makeNode()
 }
 }
 
 /** Represents either a link to an animated GIF stored on the Telegram servers, or an external URL link to one. */
 struct InlineResultGIF: InlineResult {
 var type: String = "gif"            // Type of the result being given.
 var id: String                      // Unique Identifier for the result, 1-64 bytes.
 var content: InputMessageContent?   // Content of the message to be sent.
 var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
 
 var url: String // Identifier/URL depending on the above.
 var title: String? // Title.
 var caption: String? // Caption, 0-200 characters.
 var width: Int? // Width of the GIF.
 var height: Int? // Height of the GIF.
 var thumbUrl: String? // Not optional for non-cached types.  URL of the statis thumbnail for the result (JPEG or GIF)
 
 // NodeRepresentable conforming methods
 init(node: Node, in context: Context) throws {
 type = try row.get("file_id")
 id = try row.get("duration")
 if let subContent = node["input_message_content"] {
 self.content = try .init(node: subContent, in: context) as InputMessageContent }
 replyMarkup = try row.get("reply_markup")
 }
 
 func makeNode() throws -> Node {
 var keys: [String:NodeRepresentable] = [
 "type": type,
 "id": id]
 
 // Optional keys
 if content != nil { keys["input_message_content"] = content }
 if replyMarkup != nil { keys["reply_markup"] = replyMarkup }
 
 return try Node(node: keys)
 }
 
 func makeNode(context: Context) throws -> Node {
 return try self.makeNode()
 }
 }
 
 
 /** Represents either a link to a video animation (H.264/MPEG-4 AVC video without sound) stored on the Telegram servers, or an external URL link to one. */
 struct InlineResultMpeg4GIF: InlineResult {
 var type: String = "mpeg4_gif"      // Type of the result being given.
 var id: String                      // Unique Identifier for the result, 1-64 bytes.
 var content: InputMessageContent?   // Content of the message to be sent.
 var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
 
 var url: String // Identifier/URL depending on the above.
 var title: String? // Title.
 var caption: String? // Caption, 0-200 characters.
 
 var thumb: InlineThumbnail
 
 // NodeRepresentable conforming methods
 init(node: Node, in context: Context) throws {
 type = try row.get("file_id")
 id = try row.get("duration")
 if let subContent = node["input_message_content"] {
 self.content = try .init(node: subContent, in: context) as InputMessageContent }
 replyMarkup = try row.get("reply_markup")
 
 }
 
 func makeNode() throws -> Node {
 var keys: [String:NodeRepresentable] = [
 "type": type,
 "id": id]
 
 // Optional keys
 if content != nil { keys["input_message_content"] = content }
 if replyMarkup != nil { keys["reply_markup"] = replyMarkup }
 
 return try Node(node: keys)
 }
 
 func makeNode(context: Context) throws -> Node {
 return try self.makeNode()
 }
 
 }
 
 /** Represents either a link to a photo stored on the Telegram servers, or an external URL link to one. */
 struct InlineResultPhoto: InlineResult {
 var type: String = "photo"          // Type of the result being given.
 var id: String                      // Unique Identifier for the result, 1-64 bytes.
 var content: InputMessageContent?   // Content of the message to be sent.
 var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
 
 var url: String // Either a valid identifier for the audio file if cached, or a URL if not.
 
 var title: String? // Title.
 var caption: String? // Caption, 0-200 characters.
 var description: String? // Short description of the result.
 var thumb: InlineThumbnail
 
 // NodeRepresentable conforming methods
 init(node: Node, in context: Context) throws {
 type = try row.get("file_id")
 id = try row.get("duration")
 if let subContent = node["input_message_content"] {
 self.content = try .init(node: subContent, in: context) as InputMessageContent }
 replyMarkup = try row.get("reply_markup")
 
 }
 
 func makeNode() throws -> Node {
 var keys: [String:NodeRepresentable] = [
 "type": type,
 "id": id]
 
 // Optional keys
 if content != nil { keys["input_message_content"] = content }
 if replyMarkup != nil { keys["reply_markup"] = replyMarkup }
 
 return try Node(node: keys)
 }
 
 func makeNode(context: Context) throws -> Node {
 return try self.makeNode()
 }
 }
 
 
 /** Represents a link to a sticker stored on the Telegram servers.  Stickers can only ever be cached. */
 struct InlineResultSticker: InlineResult {
 var type: String = "sticker"        // Type of the result being given.
 var id: String                      // Unique Identifier for the result, 1-64 bytes.
 var content: InputMessageContent?   // Content of the message to be sent.
 var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
 
 var isCached: Bool = true // Determines whether the given audio result is cached (stored on Telegram's servers) or not.
 var fileLink: String // Either a valid identifier for the audio file if cached, or a URL if not.
 
 // NodeRepresentable conforming methods
 init(node: Node, in context: Context) throws {
 type = try row.get("file_id")
 id = try row.get("duration")
 if let subContent = node["input_message_content"] {
 self.content = try .init(node: subContent, in: context) as InputMessageContent }
 replyMarkup = try row.get("reply_markup")
 
 }
 
 func makeNode() throws -> Node {
 var keys: [String:NodeRepresentable] = [
 "type": type,
 "id": id]
 
 // Optional keys
 if content != nil { keys["input_message_content"] = content }
 if replyMarkup != nil { keys["reply_markup"] = replyMarkup }
 
 return try Node(node: keys)
 }
 
 func makeNode(context: Context) throws -> Node {
 return try self.makeNode()
 }
 }
 
 /** Represents either a link to a video stored on the Telegram servers, or an external URL link to a page containing an embedded video player or video file. */
 struct InlineResultVideo: InlineResult {
 var type: String = "video"          // Type of the result being given.
 var id: String                      // Unique Identifier for the result, 1-64 bytes.
 var content: InputMessageContent?   // Content of the message to be sent.
 var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
 
 var isCached: Bool // Determines whether the given audio result is cached (stored on Telegram's servers) or not.
 var fileLink: String // Either a valid identifier for the audio file if cached, or a URL if not.
 
 var title: String? // Title.
 var caption: String? // Caption, 0-200 characters.
 
 var mimeType: String // Mime type of the content of the file, either “text/html" or "video/mp4"
 var thumb: InlineThumbnail // URL of the thumbbail for the result.
 var duration: Int? // Video duration in seconds.
 
 // NodeRepresentable conforming methods
 init(node: Node, in context: Context) throws {
 type = try row.get("file_id")
 id = try row.get("duration")
 if let subContent = node["input_message_content"] {
 self.content = try .init(node: subContent, in: context) as InputMessageContent }
 replyMarkup = try row.get("reply_markup")
 
 }
 
 func makeNode() throws -> Node {
 var keys: [String:NodeRepresentable] = [
 "type": type,
 "id": id]
 
 // Optional keys
 if content != nil { keys["input_message_content"] = content }
 if replyMarkup != nil { keys["reply_markup"] = replyMarkup }
 
 return try Node(node: keys)
 }
 
 func makeNode(context: Context) throws -> Node {
 return try self.makeNode()
 }
 }
 
 /** Represents either a link to a voice message (in an .ogg container encoded with OPUS) stored on the Telegram servers, or an external URL link to one. */
 struct InlineResultVoice: InlineResult {
 var type: String = "voice"          // Type of the result being given.
 var id: String                      // Unique Identifier for the result, 1-64 bytes.
 var content: InputMessageContent?   // Content of the message to be sent.
 var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
 
 var isCached: Bool // Determines whether the given audio result is cached (stored on Telegram's servers) or not.
 var fileLink: String // Either a valid identifier for the audio file if cached, or a URL if not.
 
 var title: String // Title.
 var caption: String? // Caption, 0-200 characters.
 var duration: Int? // Audio duration in seconds.
 
 // NodeRepresentable conforming methods
 init(node: Node, in context: Context) throws {
 type = try row.get("file_id")
 id = try row.get("duration")
 if let subContent = node["input_message_content"] {
 self.content = try .init(node: subContent, in: context) as InputMessageContent }
 replyMarkup = try row.get("reply_markup")
 }
 
 func makeNode() throws -> Node {
 var keys: [String:NodeRepresentable] = [
 "type": type,
 "id": id]
 
 // Optional keys
 if content != nil { keys["input_message_content"] = content }
 if replyMarkup != nil { keys["reply_markup"] = replyMarkup }
 
 return try Node(node: keys)
 }
 
 func makeNode(context: Context) throws -> Node {
 return try self.makeNode()
 }
 }
 
 */

/**
Represents the content of a message to be sent as a result of an inline query.
- warning: DO NOT USE THIS CLASS, USE A SUB-CLASS.
*/
public protocol InputMessageContent: Model {

}

final public class InputMessageText: InputMessageContent {
	public var storage = Storage()
	
  var text: String // Text of the message to be sent.  1-4096 characters.
  var parseMode: String? // Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in your bot's message.
  var disableWebPreview: Bool? // Disables link previews for links in the sent message.
  
  init(text: String, parseMode: String?, disableWebPreview: Bool?) {
    self.text = text
    self.parseMode = parseMode
    self.disableWebPreview = disableWebPreview
  }
  
  // NodeRepresentable conforming methods
  public required init(row: Row) throws {
    text = try row.get("message_text")
    parseMode = try row.get("parse_mode")
    disableWebPreview = try row.get("disable_web_page_preview")
		
  }
	
  public func makeRow() throws -> Row {
    var row = Row()
		try row.set("message_text", text)
		try row.set("parse_mode", parseMode)
		try row.set("disable_web_page_preview", disableWebPreview)
    
    return row
  }
}

final public class InputMessageLocation: InputMessageContent {
	public var storage = Storage()
	
  var latitude: Float // Latitude of the venue in degrees.
  var longitude: Float // Longitude of the venue in degrees.
  
  init(latitude: Float, longitude: Float) {
    self.latitude = latitude
    self.longitude = longitude
  }
  
  // NodeRepresentable conforming methods
  public init(row: Row) throws {
    latitude = try row.get("latitude")
    longitude = try row.get("longitude")
  }
  
  public func makeRow() throws -> Row {
    var row = Row()
		try row.set("latitude", latitude)
		try row.set("longitude", longitude)
		
		return row
  }
}



final public class InputMessageVenue: InputMessageContent {
	public var storage = Storage()
	
  var latitude: Float // Latitude of the venue in degrees.
  var longitude: Float // Longitude of the venue in degrees.
  var title: String // Name of the venue.
  var address: String // Address of the venue.
  var foursquareID: String? // Foursquare identifier of the venue, if known.
  
	init() {
    self.latitude = 0
    self.longitude = 0
    self.title = ""
    self.address = ""
  }
  
  // NodeRepresentable conforming methods
  public init(row: Row) throws {
    latitude = try row.get("latitude")
    longitude = try row.get("longitude")
    title = try row.get("title")
    address = try row.get("address")
    foursquareID = try row.get("foursquare_id")
  }
  
  public func makeRow() throws -> Row {
    var row = Row()
		try row.set("latitude", latitude)
		try row.set("longitude", longitude)
		try row.set("title", title)
		try row.set("address", address)
		try row.set("foursquare_id", foursquareID)
		
		return row
	}
}

final public class InputMessageContact: InputMessageContent {
	public var storage = Storage()
	
  var phoneNumber: String // Contact's phone number.
  var firstName: String // Contact's first name.
  var lastName: String // Contact's last name.
  
	init() {
    self.phoneNumber = ""
    self.firstName = ""
    self.lastName = ""
  }
  
  // NodeRepresentable conforming methods
  public init(row: Row) throws {
    phoneNumber = try row.get("phone_number")
    firstName = try row.get("first_name")
    lastName = try row.get("last_name")
  }
  
  public func makeRow() throws -> Row {
		var row = Row()
		try row.set("phone_number", phoneNumber)
		try row.set("first_name", firstName)
		try row.set("last_name", lastName)
		
		return row
	}
	
}



