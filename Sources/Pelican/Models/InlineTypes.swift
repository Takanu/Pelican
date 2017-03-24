
import Foundation
import Vapor

// Represents an incoming inline query. When the user sends an empty query, your bot could return some default or trending results.
class InlineQuery: NodeConvertible, JSONConvertible {
    var id: String // Unique identifier for this query.
    var from: User // The sender.
    var query: String // Text of the query (up to 512 characters).
    var offset: String // Offset of the results to be returned, is bot-controllable.
    var location: Location? // Sender location, only for bots that request it.
    
    // NodeRepresentable conforming methods
    required init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        
        guard let subUser = node["from"] else { throw TGTypeError.ExtractFailed }
        self.from = try .init(node: subUser, in: context) as User
        
        query = try node.extract("query")
        offset = try node.extract("offset")
        
        if let subLocation = node["location"] {
            self.location = try .init(node: subLocation, in: context) as Location }
    }
    
    func makeNode() throws -> Node {
        var keys: [String:NodeRepresentable] = [
            "id": id,
            "from": from,
            "query": query,
            "offset": offset
        ]
        
        if location != nil { keys["location"] = location }
        return try Node(node: keys)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}


/* Represents a result of an inline query that was chosen by the user and sent to their chat partner. */
struct ChosenInlineResult {
    var id: String // The unique identifier for the result that was chosen.
    var from: User // The user that chose the result.
    var query: String // The query that was used to obtain the result
    var location: Location? // Sender location, only for bots that require user location.
    var inlineMessageID: String? // Identifier of the sent inline message. Available only if there is an inline keyboard attached to the message.
    
    // NodeRepresentable conforming methods
    init(node: Node, in context: Context) throws {
        id = try node.extract("result_id")
        
        guard let subUser = node["from"] else { throw TGTypeError.ExtractFailed }
        self.from = try .init(node: subUser, in: context) as User
        
        query = try node.extract("query")
        
        if let subLocation = node["location"] {
            self.location = try .init(node: subLocation, in: context) as Location }
        
        inlineMessageID = try node.extract("inline_message_id")
        
    }
    
    func makeNode() throws -> Node {
        var keys: [String:NodeRepresentable] = [
            "result_id": id,
            "from": from,
            "query": query]
        
        // Optional keys
        if location != nil { keys["location"] = location }
        if inlineMessageID != nil { keys["inline_message_id"] = inlineMessageID }
        return try Node(node: keys)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}



// Used for a result/your response of an inline query.
protocol InlineResult: NodeConvertible, JSONConvertible {
    
}

struct InlineResultArticle: InlineResult {
    var type: String = "article"        // Type of the result being given.
    var id: String                      // Unique Identifier for the result, 1-64 bytes.
    var content: InputMessageContent    // Content of the message to be sent.
    var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
    
    var title: String                   // TItle of the result.
    var url: String?                    // URL of the result.
    var hideUrl: Bool?                  // Set as true if you don't want the URL to be shown in the message.
    var description: String?            // Short description of the result.
    var thumb: InlineThumbnail?         // Inline thumbnail type.
    
    init(id: String, title: String, message: String, description: String, markup: MarkupInline?) {
        self.id = id
        self.title = title
        self.content = InputMessageText(text: message, parseMode: "", disableWebPreview: nil)
        self.replyMarkup = markup
        self.description = description
    }
    
    init(id: String, title: String, description: String, contents: String, markup: MarkupInline?) {
        self.id = id
        self.title = title
        self.content = InputMessageText(text: contents, parseMode: "", disableWebPreview: nil)
        self.replyMarkup = markup
        self.description = description
    }
    
    // NodeRepresentable conforming methods
    init(node: Node, in context: Context) throws {
        type = try node.extract("type")
        id = try node.extract("id")
        
        // This likely will fail, need another solution
        guard let subContent = node["input_message_content"] else { throw TGTypeError.ExtractFailed }
        self.content = try .init(node: subContent, in: context) as InputMessageContent
        
        replyMarkup = try node.extract("reply_markup")
        
        // Non-core extractions
        title = try node.extract("title")
        url = try node.extract("url")
        hideUrl = try node.extract("hide_url")
        description = try node.extract("description")
        thumb = try InlineThumbnail(node: node, in: TGContext.response)
    }
    
    
    func makeNode() throws -> Node {
        var keys: [String:NodeRepresentable] = [
            "type": type,
            "id": id,
            "title": title,
            "input_message_content": content]
        
        // Optional keys
        if replyMarkup != nil { keys["reply_markup"] = replyMarkup }
        if url != nil { keys["url"] = url }
        if hideUrl != nil { keys["hide_url"] = hideUrl }
        if description != nil { keys["description"] = description }
        //if thumb != nil { keys["thumb"] = thumb }
        
        return try Node(node: keys)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
    
}

struct InlineResultContact: InlineResult {
    var type: String = "contact"        // Type of the result being given.
    var id: String                      // Unique Identifier for the result, 1-64 bytes.
    var content: InputMessageContent?   // Content of the message to be sent.
    var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
    
    var phoneNumber: String             // Contact's phone number.
    var firstName: String               // Contact's first name.
    var lastName: String?               //  Contact's last name.
    var thumb: InlineThumbnail?         // Inline thumbnail type.
    
    // NodeRepresentable conforming methods
    init(node: Node, in context: Context) throws {
        type = try node.extract("type")
        id = try node.extract("id")
        
        if let subContent = node["input_message_content"] {
            self.content = try .init(node: subContent, in: context) as InputMessageContent }
        
        replyMarkup = try node.extract("reply_markup")
        
        // Non-core extractions
        phoneNumber = try node.extract("phone_number")
        firstName = try node.extract("first_name")
        lastName = try node.extract("last_name")
        thumb = try InlineThumbnail(node: node, in: TGContext.response)
        
    }
    
    func makeNode() throws -> Node {
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
    
    func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}

struct InlineResultLocation: InlineResult {
    var type: String = "location"       // Type of the result being given.
    var id: String                      // Unique Identifier for the result, 1-64 bytes.
    var content: InputMessageContent?   // Content of the message to be sent.
    var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
    
    var title: String                   // Location title.
    var latitude: Float                 // Location latitude in degrees.
    var longitude: Float                // Location longitude in degrees.
    var thumb: InlineThumbnail?         // Inline thumbnail type.
    
    // NodeRepresentable conforming methods
    init(node: Node, in context: Context) throws {
        type = try node.extract("type")
        id = try node.extract("id")
        
        if let subContent = node["input_message_content"] {
            self.content = try .init(node: subContent, in: context) as InputMessageContent }
        
        replyMarkup = try node.extract("reply_markup")
        
        // Non-core extractions
        title = try node.extract("title")
        latitude = try node.extract("latitude")
        longitude = try node.extract("longitude")
        thumb = try InlineThumbnail(node: node, in: TGContext.response)
    }
    
    func makeNode() throws -> Node {
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
    
    func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}

struct InlineResultVenue: InlineResult {
    var type: String = "venue"          // Type of the result being given.
    var id: String                      // Unique Identifier for the result, 1-64 bytes.
    var content: InputMessageContent?   // Content of the message to be sent.
    var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
    
    var title: String                   // Location title.
    var address: String                 // Address of the venue.
    var latitude: Float                 // Location latitude in degrees.
    var longitude: Float                // Location longitude in degrees.
    var foursquareID: String?           // Foursquare identifier of the venue if know.
    var thumb: InlineThumbnail?         // Inline thumbnail type.
    
    // NodeRepresentable conforming methods
    init(node: Node, in context: Context) throws {
        type = try node.extract("type")
        id = try node.extract("id")
        
        if let subContent = node["input_message_content"] {
            self.content = try .init(node: subContent, in: context) as InputMessageContent }
        
        replyMarkup = try node.extract("reply_markup")
        
        // Non-core extractions
        title = try node.extract("title")
        address = try node.extract("address")
        latitude = try node.extract("latitude")
        longitude = try node.extract("longitude")
        foursquareID = try node.extract("foursquare_id")
        thumb = try InlineThumbnail(node: node, in: TGContext.response)
        
    }
    
    func makeNode() throws -> Node {
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
    
    func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}

struct InlineResultGame: InlineResult {
    var type: String = "game"           // Type of the result being given.
    var id: String                      // Unique Identifier for the result, 1-64 bytes.
    var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
    var name: String                    // Short name of the game
    
    // NodeRepresentable conforming methods
    init(node: Node, in context: Context) throws {
        type = try node.extract("type")
        id = try node.extract("id")
        replyMarkup = try node.extract("reply_markup")
        name = try node.extract("game_short_name")
        
    }
    
    func makeNode() throws -> Node {
        var keys: [String:NodeRepresentable] = [
            "type": type,
            "id": id,
            "game_short_name": name]
        
        // Optional keys
        if replyMarkup != nil { keys["reply_markup"] = replyMarkup }
        return try Node(node: keys)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}



enum InlineResultError: String, Error {
    case idNotFound = "ID not found during node initialisation."
    
}


/*
// makeNode() currently makes no effort to divide content based on whether it's cached or not.
// Use getQuery() instead.

/* Represents either a link to a MP3 audio file stored on the Telegram servers, or an external URL link to one. */
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
        type = try node.extract("file_id")
        id = try node.extract("duration")
        if let subContent = node["input_message_content"] {
            self.content = try .init(node: subContent, in: context) as InputMessageContent }
        replyMarkup = try node.extract("reply_markup")
        
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

/* Represents either a link to a file stored on the Telegram servers, or an external URL link to one.  If sent using an external link, only .PDF and .ZIP files are supported. */
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
        type = try node.extract("file_id")
        id = try node.extract("duration")
        if let subContent = node["input_message_content"] {
            self.content = try .init(node: subContent, in: context) as InputMessageContent }
        replyMarkup = try node.extract("reply_markup")
        
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

/* Represents either a link to an animated GIF stored on the Telegram servers, or an external URL link to one. */
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
        type = try node.extract("file_id")
        id = try node.extract("duration")
        if let subContent = node["input_message_content"] {
            self.content = try .init(node: subContent, in: context) as InputMessageContent }
        replyMarkup = try node.extract("reply_markup")
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


/* Represents either a link to a video animation (H.264/MPEG-4 AVC video without sound) stored on the Telegram servers, or an external URL link to one. */
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
        type = try node.extract("file_id")
        id = try node.extract("duration")
        if let subContent = node["input_message_content"] {
            self.content = try .init(node: subContent, in: context) as InputMessageContent }
        replyMarkup = try node.extract("reply_markup")
        
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

/* Represents either a link to a photo stored on the Telegram servers, or an external URL link to one. */
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
        type = try node.extract("file_id")
        id = try node.extract("duration")
        if let subContent = node["input_message_content"] {
            self.content = try .init(node: subContent, in: context) as InputMessageContent }
        replyMarkup = try node.extract("reply_markup")
        
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


/* Represents a link to a sticker stored on the Telegram servers.  Stickers can only ever be cached. */
struct InlineResultSticker: InlineResult {
    var type: String = "sticker"        // Type of the result being given.
    var id: String                      // Unique Identifier for the result, 1-64 bytes.
    var content: InputMessageContent?   // Content of the message to be sent.
    var replyMarkup: MarkupInline?      // Inline keyboard attached to the message
    
    var isCached: Bool = true // Determines whether the given audio result is cached (stored on Telegram's servers) or not.
    var fileLink: String // Either a valid identifier for the audio file if cached, or a URL if not.
    
    // NodeRepresentable conforming methods
    init(node: Node, in context: Context) throws {
        type = try node.extract("file_id")
        id = try node.extract("duration")
        if let subContent = node["input_message_content"] {
            self.content = try .init(node: subContent, in: context) as InputMessageContent }
        replyMarkup = try node.extract("reply_markup")
        
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

/* Represents either a link to a video stored on the Telegram servers, or an external URL link to a page containing an embedded video player or video file. */
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
        type = try node.extract("file_id")
        id = try node.extract("duration")
        if let subContent = node["input_message_content"] {
            self.content = try .init(node: subContent, in: context) as InputMessageContent }
        replyMarkup = try node.extract("reply_markup")
        
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

/* Represents either a link to a voice message (in an .ogg container encoded with OPUS) stored on the Telegram servers, or an external URL link to one. */
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
        type = try node.extract("file_id")
        id = try node.extract("duration")
        if let subContent = node["input_message_content"] {
            self.content = try .init(node: subContent, in: context) as InputMessageContent }
        replyMarkup = try node.extract("reply_markup")
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

// Represents the content of a message to be sent as a result of an inline query.
class InputMessageContent: NodeConvertible, JSONConvertible {
    
    init() {}
    
    // NodeRepresentable conforming methods
    required init(node: Node, in context: Context) throws {
    }
    
    func makeNode() throws -> Node {
        return try Node(node:["":0])
    }
    
    func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}

class InputMessageText: InputMessageContent {
    var text: String // Text of the message to be sent.  1-4096 characters.
    var parseMode: String? // Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in your bot's message.
    var disableWebPreview: Bool? // Disables link previews for links in the sent message.
    
    init(text: String, parseMode: String?, disableWebPreview: Bool?) {
        self.text = text
        self.parseMode = parseMode
        self.disableWebPreview = disableWebPreview
        super.init()
    }
    
    // NodeRepresentable conforming methods
    required init(node: Node, in context: Context) throws {
        text = try node.extract("message_text")
        parseMode = try node.extract("parse_mode")
        disableWebPreview = try node.extract("disable_web_page_preview")
        try super.init(node: node, in: context)
    }
    
    override func makeNode() throws -> Node {
        var keys: [String:NodeRepresentable] = [
            "message_text": text]
        
        // Optional keys
        if parseMode != nil { keys["parse_mode"] = parseMode }
        if disableWebPreview != nil { keys["disable_web_page_preview"] = disableWebPreview }
        return try Node(node: keys)
    }
    
    override func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}

class InputMessageLocation: InputMessageContent {
    var latitude: Float // Latitude of the venue in degrees.
    var longitude: Float // Longitude of the venue in degrees.
    
    init(latitude: Float, longitude: Float) {
        self.latitude = latitude
        self.longitude = longitude
        super.init()
    }
    
    // NodeRepresentable conforming methods
    required init(node: Node, in context: Context) throws {
        latitude = try node.extract("latitude")
        longitude = try node.extract("longitude")
        try super.init(node: node, in: context)
    }
    
    override func makeNode() throws -> Node {
        let keys: [String:NodeRepresentable] = [
            "latitude": latitude,
            "longitude": longitude]
        return try Node(node: keys)
    }
    
    override func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}



class InputMessageVenue: InputMessageContent {
    var latitude: Float // Latitude of the venue in degrees.
    var longitude: Float // Longitude of the venue in degrees.
    var title: String // Name of the venue.
    var address: String // Address of the venue.
    var foursquareID: String? // Foursquare identifier of the venue, if known.
    
    override init() {
        self.latitude = 0
        self.longitude = 0
        self.title = ""
        self.address = ""
        super.init()
    }
    
    // NodeRepresentable conforming methods
    required init(node: Node, in context: Context) throws {
        latitude = try node.extract("latitude")
        longitude = try node.extract("longitude")
        title = try node.extract("title")
        address = try node.extract("address")
        foursquareID = try node.extract("foursquare_id")
        try super.init(node: node, in: context)
    }
    
    override func makeNode() throws -> Node {
        var keys: [String:NodeRepresentable] = [
            "latitude": latitude,
            "longitude": longitude,
            "title": title,
            "address": address]
        
        if foursquareID != nil { keys["foursquare_id"] = foursquareID }
        return try Node(node: keys)
    }
    
    override func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
    
}

class InputMessageContact: InputMessageContent {
    var phoneNumber: String // Contact's phone number.
    var firstName: String // Contact's first name.
    var lastName: String // Contact's last name.
    
    override init() {
        self.phoneNumber = ""
        self.firstName = ""
        self.lastName = ""
        super.init()
    }
    
    // NodeRepresentable conforming methods
    required init(node: Node, in context: Context) throws {
        phoneNumber = try node.extract("phone_number")
        firstName = try node.extract("first_name")
        lastName = try node.extract("last_name")
        try super.init(node: node, in: context)
    }
    
    override func makeNode() throws -> Node {
        let keys: [String:NodeRepresentable] = [
            "phone_number": phoneNumber,
            "first_name": firstName,
            "last_name": lastName]
        
        return try Node(node: keys)
    }
    
    override func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
    
}



