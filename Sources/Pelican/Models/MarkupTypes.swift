
import Foundation
import Vapor

public protocol MarkupType: NodeConvertible, JSONConvertible {
    
}

public extension MarkupType {
    func getQuery() -> String {
        return try! self.makeJSON().serialize().toString()
    }
}

// Represents a custom keyboard with custom fancy options.
// Needs a method for automatically adding buttons into a row
public class MarkupKeyboard: NodeConvertible, JSONConvertible, MarkupType {
    public var keyboard: [MarkupKeyboardRow] = [] // The array of available keyboard buttons
    public var resizeKeyboard: Bool = true // (Optional) Requests clients to resize the keyboard vertically for optimal fit (e.g., make the keyboard smaller if there are just two rows of buttons).
    public var oneTimeKeyboard: Bool = false // (Optional) Requests clients to hide the keyboard as soon as it's been used.
    public var selective: Bool = false // (Optional)  Use this parameter if you want to show the keyboard to specific users only.
                                // Targets: 1) users that are @mentioned in the text of the Message object; 
                                // 2) if the bot's message is a reply (has reply_to_message_id), sender of the original message.
    
    public var description: String = ""
    
    public init(withButtons buttons: [String], resize: Bool = true, oneTime: Bool = false, selective: Bool = false) {
        var row = MarkupKeyboardRow()
        for button in buttons {
            row.addNewButton(button)
        }
        
        self.keyboard = [row]
        self.resizeKeyboard = resize
        self.oneTimeKeyboard = oneTime
        self.selective = selective
    }
    
    public init(withButtonRows rows: [[String]], resize: Bool = true, oneTime: Bool = false, selective: Bool = false) {
        for array in rows {
            let row = MarkupKeyboardRow(withButtonArray: array)
            keyboard.append(row)
        }
        
        self.resizeKeyboard = resize
        self.oneTimeKeyboard = oneTime
        self.selective = selective
    }
    
    public init(resize: Bool = true, oneTime: Bool = false, selective: Bool = false, buttons: String...) {
        var row = MarkupKeyboardRow()
        for button in buttons {
            row.addNewButton(button)
        }
        
        self.keyboard = [row]
        self.resizeKeyboard = resize
        self.oneTimeKeyboard = oneTime
        self.selective = selective

    }
    
    public func getButtons() -> [String] {
        var result: [String] = []
        
        for row in keyboard {
            for key in row.keys {
                result.append(key.text)
            }
        }
        
        return result
    }
    
    // Ignore context, just try and build an object from a node.
    required public init(node: Node, in context: Context) throws {
        keyboard = try node.extract("keyboard")
        resizeKeyboard = try node.extract("resize_keyboard")
        oneTimeKeyboard = try node.extract("one_time_keyboard")
        selective = try node.extract("selective")
    }
    
    public func makeNode() throws -> Node {
        let keyNode = try! keyboard.makeNode()
        print(keyNode)
        
        return try Node(node:[
            "keyboard": keyNode,
            "resize_keyboard": resizeKeyboard,
            "one_time_keyboard": oneTimeKeyboard,
            "selective": selective
            ])
    }
    
    // I need the context implementation as well, *sigh*
    public func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}

public struct MarkupKeyboardRow: NodeConvertible, JSONConvertible {
    public var keys: [MarkupKeyboardKey] = []
    
    public init(withButtons buttons: String...) {
        for button in buttons {
            keys.append(MarkupKeyboardKey(label: button))
        }
    }
    
    public init(withButtonArray array: [String]) {
        for label in array {
            keys.append(MarkupKeyboardKey(label: label))
        }
    }
    
    public mutating func addButton(_ button: MarkupKeyboardKey) {
        keys.append(button)
    }
    
    public mutating func addNewButton(_ label: String) {
        keys.append(MarkupKeyboardKey(label: label))
    }
    
    // Ignore context, just try and build an object from a node.
    public init(node: Node, in context: Context) throws {
        let array = node.nodeArray!
        for item in array {
            keys.append(try! MarkupKeyboardKey(node: item, in: context))
        }
    }
    
    public func makeNode() throws -> Node {
        return try keys.makeNode()
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}

public struct MarkupKeyboardKey: NodeConvertible, JSONConvertible {
    public var text: String // The text displayed on the button.  If no other optional is used, this will be sent to the bot when pressed.
    private var requestContact: Bool = false // (Optional) If True, the user's phone number will be sent as a contact when the button is pressed. Available in private chats only
    private var requestLocation: Bool = false // (Optional) If True, the user's current location will be sent when the button is pressed. Available in private chats only
    
    init(label: String) {
        text = label
    }
    
    // Ignore context, just try and build an object from a node.
    public init(node: Node, in context: Context) throws {
        text = try node.extract("text")
        requestContact = try node.extract("request_contact") ?? false
        requestLocation = try node.extract("request_location") ?? false
    }
    
    public func makeNode() throws -> Node {
        var keys = [String:NodeRepresentable]()
        keys["text"] = text
        if requestContact == true && requestLocation == false {
            keys["request_contact"] = requestContact
        }
        if requestContact == false && requestLocation == true {
            keys["request_location"] = requestLocation
        }
        
        return try Node(node: keys)
    }
    
    // I need the context implementation as well, *sigh*
    public func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}


/// A series of inline buttons to be displayed with a message sent from the bot
public class MarkupInline: NodeConvertible, JSONConvertible, MarkupType {
    public var keyboard: [MarkupInlineRow] = []
    
    // Blank!
    public init() {
        return
    }
    
    // If you want to do it the hard way
    public init(withButtons buttonsIn: MarkupInlineKey...) {
        var row = MarkupInlineRow()
        for button in buttonsIn {
            row.addButton(button)
        }
        keyboard.append(row)
    }
    // A quick type for generating buttons.
    public init(withURL pair: (label: String, url: String)...) {
        var row = MarkupInlineRow()
        for label in pair {
            let button = MarkupInlineKey(fromURL: label.url, label: label.label)
            row.addButton(button)
        }
        keyboard.append(row)
    }
    
    // A quick type for generating buttons.
    public init(withCallback pair: (label: String, query: String)...) {
        var row = MarkupInlineRow()
        for label in pair {
            let button = MarkupInlineKey(fromCallbackData: label.query, label: label.label)
            row.addButton(button)
        }
        keyboard.append(row)
    }
    
    /* Should only be used when the class has no plans to be updated and is the only inline control currently active.*/
    public init(withGenCallback labels: String...) {
        var row = MarkupInlineRow()
        var id = 1
        for label in labels {
            let button = MarkupInlineKey(fromCallbackData: String(id), label: label)
            row.addButton(button)
            id += 1
        }
        keyboard.append(row)
    }
    
    /* Should only be used when the class has no plans to be updated and is the only inline control currently active.*/
    public init(withGenCallback rows: [[String]]) {
        var id = 1
        for row in rows {
            var newRow = MarkupInlineRow()
            for label in row {
                let button = MarkupInlineKey(fromCallbackData: String(id), label: label)
                newRow.addButton(button)
                id += 1
            }
            keyboard.append(newRow)
        }
        
    }
    
    // A quick type for generating buttons.
    public init(withCurrentInlineQuery pair: (label: String, query: String)...) {
        var row = MarkupInlineRow()
        for label in pair {
            let button = MarkupInlineKey(fromInlineQueryCurrent: label.query, label: label.label)
            row.addButton(button)
        }
        keyboard.append(row)
    }
    
    public init(withCurrentInlineQuery array: [(label: String, query: String)]) {
        var row = MarkupInlineRow()
        for label in array {
            let button = MarkupInlineKey(fromInlineQueryCurrent: label.query, label: label.label)
            row.addButton(button)
        }
        keyboard.append(row)
    }
    
    /*
    func addTextButton(label: String, row: Int) {
        let button = InlineButton(label: label)
        //buttons.append(button)
    }
    func addURLButton(label: String, url: String, row: Int) {
        let button = InlineButton(fromURL: url, label: label)
        //buttons.append(button)
    }
    */
    
    /// Returns all available callback data from any button held inside this markup
    public func getCallbackData() -> [String]? {
        var data: [String] = []
        for row in keyboard {
            for key in row.keys {
                
                switch key.optional {
                case .callbackData(let callback):
                    data.append(callback)
                default:
                    continue
                }
            }
        }
        
        return data
    }
    
    // Ignore context, just try and build an object from a node.
    public required init(node: Node, in context: Context) throws {
        keyboard = try node.extract("keyboard")
    }
    
    public func makeNode() throws -> Node {
        return try Node(node:["inline_keyboard":keyboard.makeNode()])
    }
    
    // I need the context implementation as well, *sigh*
    public func makeNode(context: Context) throws -> Node {
        return try Node(node:["inline_keyboard":keyboard.makeNode()])
    }

    
}

public struct MarkupInlineRow: NodeConvertible, JSONConvertible {
    public var keys: [MarkupInlineKey] = []
    
    public init() {
    }
    
    // If you want to do it the hard way
    public init(withButtons buttonsIn: MarkupInlineKey...) {
        for button in buttonsIn {
            keys.append(button)
        }
    }
    
    // A quick type for generating buttons.
    public init(withURL pair: (String, String)...) {
        for label in pair {
            let button = MarkupInlineKey(fromURL: label.0, label: label.1)
            keys.append(button)
        }
    }
    public mutating func addButton(_ button: MarkupInlineKey) {
        keys.append(button)
    }
    
    // Ignore context, just try and build an object from a node.
    public init(node: Node, in context: Context) throws {
        let array = node.nodeArray!
        for item in array {
            keys.append(try! MarkupInlineKey(node: item, in: context))
        }
    }
    
    public func makeNode() throws -> Node {
        return try keys.makeNode()
    }
    
    // I need the context implementation as well, *sigh*
    public func makeNode(context: Context) throws -> Node {
        return try keys.makeNode()
    }

}


// A single inline button definition
public class MarkupInlineKey: NodeConvertible, JSONConvertible {
    var text: String // Label text
    fileprivate var optional: InlineButtonOptional
    
    
    public init(fromURL url: String, label: String) {
        text = label
        optional = .url(url)
    }
    
    public init(fromCallbackData callback: String, label: String) {
        text = label
        optional = .callbackData(callback)
    }
    
    public init(fromInlineQueryCurrent data: String, label: String) {
        text = label
        optional = .switchInlineQuery_currentChat(data)
    }
    
    // Ignore context, just try and build an object from a node.
    public required init(node: Node, in context: Context) throws {
        text = try node.extract("text").string
        optional = .url("")
        
        // Need to figure out how to handle the optional
    }
    
    // Now make a node from the object <3
    public func makeNode() throws -> Node {
        var keys = [String:String]()
        keys["text"] = text
        
        switch optional{
        case .url(let url):
            keys["url"] = url
        case .callbackData(let callback):
            keys["callback_data"] = callback
        case .switchInlineQuery(let query):
            keys["switch_inline_query"] = query
        case .switchInlineQuery_currentChat(let query):
            keys["switch_inline_query_current_chat"] = query
        }
        
        return try Node(node:keys)
    }
    
    // I need the context implementation as well, *sigh*
    public func makeNode(context: Context) throws -> Node {
        var keys = [String:String]()
        keys["text"] = text
        
        switch optional{
        case .url(let url):
            keys["url"] = url
        case .callbackData(let callback):
            keys["callback_data"] = callback
        case .switchInlineQuery(let query):
            keys["switch_inline_query"] = query
        case .switchInlineQuery_currentChat(let query):
            keys["switch_inline_query_current_chat"] = query
        }
        
        return try Node(node:keys)
    }
}

private enum InlineButtonOptional {
    case url(String)                            // HTTP url to be opened when button is pressed.
    case callbackData(String)                   // Data to be sent in a callback query to the bot when button is pressed, 1-64 bytes
    case switchInlineQuery(String)              // Prompts the user to select one of their chats, open it and insert the bot‘s username and the specified query in the input field.
    case switchInlineQuery_currentChat(String)  // If set, pressing the button will insert the bot‘s username and the specified inline query in the current chat's input field.  Can be empty.
}


public class MarkupKeyboardRemove: NodeConvertible, JSONConvertible, MarkupType {
    public var removeKeyboard: Bool = true // Requests clients to remove the custom keyboard (user will not be able to summon this keyboard
    public var selective: Bool = false // (Optional) Use this parameter if you want to force reply from specific users only.
    
    public init(isSelective sel: Bool) {
        selective = sel
    }
    
    // Ignore context, just try and build an object from a node.
    public required init(node: Node, in context: Context) throws {
        removeKeyboard = try node.extract("remove_keyboard")
        selective = try node.extract("selective")
        
    }
    
    // Now make a node from the object <3
    public func makeNode() throws -> Node {
        return try! Node(node:[
            "remove_keyboard": removeKeyboard,
            "selective": selective
            ])
    }
    
    // Now make a node from the object <3
    public func makeNode(context: Context) throws -> Node {
        return try! Node(node:[
            "remove_keyboard": removeKeyboard,
            "selective": selective
            ])
    }
    
}

public class MarkupForceReply: NodeConvertible, JSONConvertible, MarkupType {
    public var forceReply: Bool = true // Shows reply interface to the user, as if they manually selected the bot‘s message and tapped ’Reply'
    public var selective: Bool = false // (Optional) Use this parameter if you want to force reply from specific users only.
    
    public init(isSelective sel: Bool) {
        selective = sel
    }
    
    // Ignore context, just try and build an object from a node.
    public required init(node: Node, in context: Context) throws {
        forceReply = try node.extract("force_reply")
        selective = try node.extract("selective")
        
    }
    
    // Now make a node from the object <3
    public func makeNode() throws -> Node {
        return try! Node(node:[
            "force_reply": forceReply,
            "selective": selective
            ])
    }
    
    // Now make a node from the object <3
    public func makeNode(context: Context) throws -> Node {
        return try! Node(node:[
            "force_reply": forceReply,
            "selective": selective
            ])
    }
}
