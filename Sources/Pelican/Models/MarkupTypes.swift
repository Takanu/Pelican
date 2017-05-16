
import Foundation
import Vapor



/** 
 Represents a Telegram "Markup Type", that defines additional special actions and interfaces
 alongside a message, such as creating a custom keyboard or forcing a userto reply to the sent 
 message.
 */
public protocol MarkupType: NodeConvertible, JSONConvertible {
  
}

public extension MarkupType {
  func getQuery() -> String {
    return try! self.makeJSON().serialize().toString()
  }
}


/// Represents a static keyboard interface that when sent, appears below the message entry box on a Telegram client.
public class MarkupKeyboard: NodeConvertible, JSONConvertible, MarkupType {
  
  /// An array of keyboard rows, that contain labelled buttons which populate the message keyboard.
  public var keyboard: [[MarkupKeyboardKey]] = [[]]
  /// (Optional) Requests clients to resize the keyboard vertically for optimal fit (e.g., make the keyboard smaller if there are just two rows of buttons).
  public var resizeKeyboard: Bool = true
  /// (Optional) Requests clients to hide the keyboard as soon as it's been used.
  public var oneTimeKeyboard: Bool = false
  
  /**
  (Optional)  Use this parameter if you want to show the keyboard to specific users only.
  _ _ _
   
  **Targets**
  1) Users that are @mentioned in the text of the Message object;
  2) if the bot's message is a reply (has reply_to_message_id), sender of the original message.
   */
  public var selective: Bool = false
  
  
  //public var description: String = ""
  
  /**
   Initialises the keyboard using a set of String arrays and other optional parameters.
   - parameter rows: The keyboard as defined by a set of nested String arrays.
   - parameter resize: Requests clients to resize the keyboard vertically for an optimal fit.
   - parameter oneTime: Requests clients to hide the keyboard as soon as it's been used.
   - parameter selective: Use this parameter if you want to show the keyboard to specific users only.
   */
  public init(withButtonRows rows: [[String]], resize: Bool = true, oneTime: Bool = false, selective: Bool = false) {
    for array in rows {
      var row: [MarkupKeyboardKey] = []
      
      for label in array {
        let button = MarkupKeyboardKey(label: label)
        row.append(button)
      }
      
      keyboard.append(row)
    }
    
    self.resizeKeyboard = resize
    self.oneTimeKeyboard = oneTime
    self.selective = selective
  }
  
  /**
   Initialises the keyboard using a range of String buttons, which will be arranged as a single row.
   - parameter buttons: The keyboard as defined by a series of Strings.
   - parameter resize: Requests clients to resize the keyboard vertically for an optimal fit.
   - parameter oneTime: Requests clients to hide the keyboard as soon as it's been used.
   - parameter selective: Use this parameter if you want to show the keyboard to specific users only.
   */
  public init(resize: Bool = true, oneTime: Bool = false, selective: Bool = false, buttons: String...) {
    var row: [MarkupKeyboardKey] = []
    for button in buttons {
      row.append(MarkupKeyboardKey(label: button))
    }
    
    self.keyboard = [row]
    self.resizeKeyboard = resize
    self.oneTimeKeyboard = oneTime
    self.selective = selective
    
  }
  
  /**
   Returns all the buttons the keyboard holds, as a single array.
   */
  public func getButtons() -> [String] {
    var result: [String] = []
    
    for row in keyboard {
      for key in row {
        result.append(key.text)
      }
    }
    
    return result
  }
  
  /**
   Finds a key that matches the given label.
   - parameter label: The label of the key you wish to find   
   - returns: The key if found, or nil if not found.
   */
  public func findButton(label: String) -> MarkupKeyboardKey? {
    for row in keyboard {
      for key in row {
        
        if key.text == label {
          return key
        }
      }
    }
    
    return nil
  }
  
  /**
   Finds and replaces a keyboard button defined by the given label with a new provided one.
   - parameter oldLabel: The label to find in the keyboard
   - parameter newLabel: The label to use as a replacement
   - parameter replaceAll: (Optional) If true, any label that matches `oldLabel` will be replaced with `newLabel`, not just the first instance.
   */
  public func replaceButton(oldLabel: String, newLabel: String, replaceAll: Bool = false) -> Bool {
    var result = false
    
    for (x, row) in keyboard.enumerated() {
      var currentRow = row
      for (y, key) in row.enumerated() {
        
        if key.text == oldLabel {
          currentRow[y].text = newLabel
          result = true
          
          if replaceAll == false {
            keyboard[x] = currentRow
            return true
          }
        }
      }
      
      keyboard[x] = currentRow
    }
    
    return result
  }
  
  /**
   Finds and deletes a keyboard button thgat matches the given label
   - parameter withLabel: The label to find in the keyboard
   - parameter removeAll: (Optional) If true, any label that matches the given label will be removed.
   */
  public func removeButton(withLabel label: String, removeAll: Bool = false) -> Bool {
    var result = false
    
    for (x, row) in keyboard.enumerated() {
      var currentRow = row
      for (y, key) in row.enumerated() {
        
        if key.text == label {
          currentRow.remove(at: y)
          result = true
          
          if removeAll == false {
            keyboard[x] = currentRow
            return true
          }
        }
      }
      
      keyboard[x] = currentRow
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
    var keyNode: [Node] = []
    
    for row in keyboard {
      var rowNode: [Node] = []
      
      for key in row {
        let keyNode = try key.makeNode()
        rowNode.append(keyNode)
      }
      
      keyNode.append(try rowNode.makeNode())
    }
    
    print(keyNode)
    
    return try Node(node:[
      "keyboard": keyNode.makeNode(),
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


/// Represents a single key of a MarkupKeyboard.
public struct MarkupKeyboardKey: NodeConvertible, JSONConvertible {
  /// The text displayed on the button.  If no other optional is used, this will be sent to the bot when pressed.
  public var text: String
  /// (Optional) If True, the user's phone number will be sent as a contact when the button is pressed. Available in private chats only.
  private var requestContact: Bool = false
  // (Optional) If True, the user's current location will be sent when the button is pressed. Available in private chats only.
  private var requestLocation: Bool = false
  
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



/** 
 Represents a series of inline buttons that will be displayed underneath the message when included with it.
 
 Each inline button can do one of the following:
 _ _ _ _ _
 
 **Callback Data**
 
 This sends a small String back to the bot as a `CallbackQuery`, which is automatically filtered
 back to the session and to a `callbackState` if one exists.  
 
 Alternatively if the keyboard the button belongs to is part of a `Prompt`, it will automatically 
 be received by it in the respective Session, and the prompt will respond based on how you have set 
 it up.
 
 **URL**
 
 The button when pressed will re-direct users to a webpage.
 
 **Inine Query Switch**
 
 This can only be used when the bot supports Inline Queries.  This prompts the user to select one of their chats 
 to open it, and when open the client will insert the bot‘s username and a specified query in the input field.
 
 **Inline Query Current Chat**
 
 This can only be used when the bot supports Inline Queries.  Pressing the button will insert the bot‘s username 
 and an optional specific inline query in the current chat's input field.
 
*/
public class MarkupInline: NodeConvertible, JSONConvertible, MarkupType {
  public var keyboard: [MarkupInlineRow] = []
  
  // Blank!
  public init() {
    return
  }
  
  /**
  Creates an Inline Keyboard using a series of specified `MarkupInlineKey` types, where all buttons will 
	be arranged on a single row.
	- parameter buttonsIn: The buttons to be included in the keyboard.
  */
  public init(withButtons buttonsIn: MarkupInlineKey...) {
    let row = MarkupInlineRow()
    for button in buttonsIn {
      row.addButton(button)
    }
		keyboard.append(row)
  }
  
	/**
	Creates an Inline Keyboard using a series of specified button label and URL string pairs, where all buttons will
	be arranged on a single row.
	- parameter pair: A sequence of label/url String tuples that will define each key on the keyboard.
	*/
  public init(withURL sequence: (label: String, url: String)...) {
    let row = MarkupInlineRow()
    for tuple in sequence {
      let button = MarkupInlineKey(fromURL: tuple.url, label: tuple.label)
      row.addButton(button)
    }
    keyboard.append(row)
  }
  
	/**
	Creates an Inline Keyboard using a series of specified button label and callback String pairs, where all buttons will
	be arranged on a single row.
	- parameter pair: A sequence of label/callback String tuples that will define each key on the keyboard.
	*/
  public init(withCallback sequence: (label: String, query: String)...) {
    let row = MarkupInlineRow()
    for tuple in sequence {
      let button = MarkupInlineKey(fromCallbackData: tuple.query, label: tuple.label)
      row.addButton(button)
    }
    keyboard.append(row)
  }
	
	/**
	Creates an Inline Keyboard using sets of arrays containing label and callback tuples, where each tuple array
	is a single row.
	- parameter array: A an array of label/callback String tuple arrays that will define each row on the keyboard.
	*/
	public init(withCallback array: [[(label: String, query: String)]]) {
		for row in array {
			let newRow = MarkupInlineRow()
			for tuple in row {
				let button = MarkupInlineKey(fromCallbackData: tuple.query, label: tuple.label)
				newRow.addButton(button)
			}
			keyboard.append(newRow)
		}
	}
	
	/**
	Creates an Inline Keyboard using a series of specified button label and "Inline Query Current Chat" String pairs, where all buttons will
	be arranged on a single row.
	- parameter pair: A sequence of label/"Inline Query Current Chat" String tuples that will define each key on the keyboard.
	*/
	public init(withInlineQueryCurrent sequence: (label: String, query: String)...) {
		let row = MarkupInlineRow()
		for tuple in sequence {
			let button = MarkupInlineKey(fromInlineQueryCurrent: tuple.query, label: tuple.label)
			row.addButton(button)
		}
		keyboard.append(row)
	}
	
	/**
	Creates an Inline Keyboard using a series of specified button label and "Inline Query New Chat" String pairs, where all buttons will
	be arranged on a single row.
	- parameter pair: A sequence of label/"Inline Query New Chat" String tuples that will define each key on the keyboard.
	*/
	public init(withInlineQueryNewChat sequence: (label: String, query: String)...) {
		let row = MarkupInlineRow()
		for label in sequence {
			let button = MarkupInlineKey(fromInlineQueryNewChat: label.query, label: label.label)
			row.addButton(button)
		}
		keyboard.append(row)
	}
	
	/**
	Creates an Inline Keyboard using a series of labels.  The initializer will then generate an associated ID value for each
	label and assign it to the button as Callback data, starting with "1" and incrementing upwards.  
	
	All buttons wil be arranged on a single row.
	
	- parameter labels: A sequence of String labels that will define each key on the keyboard.
	*/
  public init(withGenCallback sequence: String...) {
    let row = MarkupInlineRow()
    var id = 1
    for label in sequence {
      let button = MarkupInlineKey(fromCallbackData: String(id), label: label)
      row.addButton(button)
      id += 1
    }
    keyboard.append(row)
  }
  
	/**
	Creates an Inline Keyboard using a set of nested String Arrays, where the array structure defines the specific arrangement
	of the keyboard.
	
	The initializer will generate an associated ID value for eachlabel and assign it to the button as Callback data, starting 
	with "1" and incrementing upwards.
	
	- parameter rows: A nested set of String Arrays, where each String array will form a single row on the inline keyboard.
	*/
  public init(withGenCallback rows: [[String]]) {
    var id = 1
    for row in rows {
      let newRow = MarkupInlineRow()
      for label in row {
        let button = MarkupInlineKey(fromCallbackData: String(id), label: label)
        newRow.addButton(button)
        id += 1
      }
      keyboard.append(newRow)
    }
    
  }
	
	/**
	Adds an extra row to the keyboard based on the sequence of buttons you provide.
	*/
	public func addRow(_ sequence: MarkupInlineKey...) {
		let newRow = MarkupInlineRow()
		
		for button in sequence {
			newRow.addButton(button)
		}
		
		keyboard.append(newRow)
	}
  
  
  /**
	Returns all available callback data from any button held inside this markup
	*/
  public func getCallbackData() -> [String]? {
    var data: [String] = []
    for row in keyboard {
      for key in row.keys {
        
        if key.type == .callbackData {
          data.append(key.data)
        }
      }
    }
    
    return data
  }
  
  /** 
	Returns all labels associated with the inline keyboard.
   */
  public func getLabels() -> [String] {
    var labels: [String] = []
		for row in keyboard {
      for key in row.keys {
          labels.append(key.text)
      }
    }
    
    return labels
  }
  
  /** 
	Returns the label thats associated with the provided data, if it exists.
   */
  public func getLabel(withData data: String) -> String? {
    for row in keyboard {
      for key in row.keys {
        
        if key.data == data { return key.text }
      }
    }
    
    return nil
  }
  
  /** 
	Returns the key thats associated with the provided data, if it exists.
   */
  public func getKey(withData data: String) -> MarkupInlineKey? {
    for row in keyboard {
      for key in row.keys {
        
        if key.data == data { return key }
      }
    }
    
    return nil
  }
  
  
  /** 
	Replaces a key with another provided one, by trying to match the given data with a key
   */
  public func replaceKey(usingType type: InlineButtonType, data: String, newKey: MarkupInlineKey) -> Bool {
    for row in keyboard {
      let result = row.replaceKey(usingType: type, data: data, newKey: newKey)
      if result == true { return true }
    }
    
    return false
  }
  
  /** 
	Replaces a key with another provided one, by trying to match the keys it has with one that's provided.
   */
  public func replaceKey(oldKey: MarkupInlineKey, newKey: MarkupInlineKey) -> Bool {
    for row in keyboard {
      let result = row.replaceKey(oldKey: oldKey, newKey: newKey)
      if result == true { return true }
    }
    
    return false
  }
  
  /** 
	Tries to find and delete a key, based on a match with one provided.
   */
  public func deleteKey(key: MarkupInlineKey) -> Bool {
    for row in keyboard {
      let result = row.deleteKey(key: key)
      if result == true { return true }
    }
    
    return false
  }
  
  
  
  
  
  public required init(node: Node, in context: Context) throws {
    keyboard = try node.extract("keyboard")
  }
  
  /// Ignore context, just try and build an object from a node.
  public func makeNode() throws -> Node {
    return try Node(node:["inline_keyboard":keyboard.makeNode()])
  }
  
  /// I need the context implementation as well, *sigh*
  public func makeNode(context: Context) throws -> Node {
    return try Node(node:["inline_keyboard":keyboard.makeNode()])
  }
  
  
}


/** 
Defines a single row on an inline keyboard.

- warning: This will likely be removed in a future version as it's not needed, please use MarkupInline instead.
 */
public class MarkupInlineRow: NodeConvertible, JSONConvertible {
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
  public func addButton(_ button: MarkupInlineKey) {
    keys.append(button)
  }
  
  
  /** Replaces a key with another provided one, by trying to match the given data with an existing key.
   */
  public func replaceKey(usingType type: InlineButtonType, data: String, newKey: MarkupInlineKey) -> Bool {
    for (i, key) in keys.enumerated() {
      
      if key.type == type {
        if key.data == data {
          keys.remove(at: i)
          keys.insert(newKey, at: i)
          return true
        }
      }
    }
    
    return false
  }
  
  /** Replaces a key with another provided one, by trying to match the provided old key with one the row has.
   */
  public func replaceKey(oldKey: MarkupInlineKey, newKey: MarkupInlineKey) -> Bool {
    for (i, key) in keys.enumerated() {
      
      if key.type == oldKey.type {
        if key.data == oldKey.data {
          keys.remove(at: i)
          keys.insert(newKey, at: i)
          return true
        }
      }
    }
    
    return false
  }
  
  /** Removes keys that match with the given key
   */
  public func deleteKey(key: MarkupInlineKey) -> Bool {
    
    for (i, key) in keys.enumerated() {
      if key.type == key.type {
        if key.data == key.data {
          
          keys.remove(at: i)
          return true
        }
      }
    }
    
    return false
  }
  
  
  
  // Ignore context, just try and build an object from a node.
  public required init(node: Node, in context: Context) throws {
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


/**
Defines a single keyboard key on a `MarkupInline` keyboard.  Each key supports one of 4 different modes:
_ _ _ _ _

**Callback Data**

This sends a small String back to the bot as a `CallbackQuery`, which is automatically filtered
back to the session and to a `callbackState` if one exists.

Alternatively if the keyboard the button belongs to is part of a `Prompt`, it will automatically
be received by it in the respective Session, and the prompt will respond based on how you have set
it up.

**URL**

The button when pressed will re-direct users to a webpage.

**Inine Query Switch**

This can only be used when the bot supports Inline Queries.  This prompts the user to select one of their chats
to open it, and when open the client will insert the bot‘s username and a specified query in the input field.

**Inline Query Current Chat**

This can only be used when the bot supports Inline Queries.  Pressing the button will insert the bot‘s username
and an optional specific inline query in the current chat's input field.
*/
public class MarkupInlineKey: NodeConvertible, JSONConvertible {
  public var text: String // Label text
  public var data: String
  public var type: InlineButtonType
  
	
	/** 
	Creates a `MarkupInlineKey` as a URL key.
	*/
  public init(fromURL url: String, label: String) {
    self.text = label
    self.data = url
    self.type = .url
  }
	
	/**
	Creates a `MarkupInlineKey` as a Callback Data key.
	*/
  public init(fromCallbackData callback: String, label: String) {
    self.text = label
    self.data = callback
    self.type = .callbackData
  }
	
	/**
	Creates a `MarkupInlineKey` as a Current Chat Inline Query key.
	*/
  public init(fromInlineQueryCurrent data: String, label: String) {
    self.text = label
    self.data = data
    self.type = .switchInlineQuery_currentChat
  }
	
	/**
	Creates a `MarkupInlineKey` as a New Chat Inline Query key.
	*/
	public init(fromInlineQueryNewChat data: String, label: String) {
		self.text = label
		self.data = data
		self.type = .switchInlineQuery
	}
	
	
  /** 
	Compares the current key with another key parameter, and returns whether or
	not the contents they hold are identical.
	*/
  public func compare(key: MarkupInlineKey) -> Bool {
    if text != key.text { return false }
    
    if key.type != self.type { return false }
    if key.data != self.data { return false }
    
    return true
    
  }
  
  // Ignore context, just try and build an object from a node.
  public required init(node: Node, in context: Context) throws {
    text = try node.extract("text").string
    data = ""
    type = .url
    
    // Need to figure out how to handle the optional
  }
  
  // Now make a node from the object <3
  public func makeNode() throws -> Node {
    var keys = [String:String]()
    keys["text"] = text
    
    switch type {
    case .url:
      keys["url"] = data
    case .callbackData:
      keys["callback_data"] = data
    case .switchInlineQuery:
      keys["switch_inline_query"] = data
    case .switchInlineQuery_currentChat:
      keys["switch_inline_query_current_chat"] = data
    }
    
    return try Node(node:keys)
  }
  
  // I need the context implementation as well, *sigh*
  public func makeNode(context: Context) throws -> Node {
    var keys = [String:String]()
    keys["text"] = text
    
    switch type {
    case .url:
      keys["url"] = data
    case .callbackData:
      keys["callback_data"] = data
    case .switchInlineQuery:
      keys["switch_inline_query"] = data
    case .switchInlineQuery_currentChat:
      keys["switch_inline_query_current_chat"] = data
    }
    
    return try Node(node:keys)
  }
}

/**
Defines what type of function a InlineButtonKey has.
*/
public enum InlineButtonType {
  case url                           // HTTP url to be opened when button is pressed.
  case callbackData                  // Data to be sent in a callback query to the bot when button is pressed, 1-64 bytes
  case switchInlineQuery             // Prompts the user to select one of their chats, open it and insert the bot‘s username and the specified query in the input field.
  case switchInlineQuery_currentChat // If set, pressing the button will insert the bot‘s username and the specified inline query in the current chat's input field.  Can be empty.
}


/**
Represents a special action that when sent with a message, will remove any `MarkupKeyboard` 
currently active, for either all of or a specified group of users.
*/
public class MarkupKeyboardRemove: NodeConvertible, JSONConvertible, MarkupType {
	
	/// Requests clients to remove the custom keyboard (user will not be able to summon this keyboard)
	var removeKeyboard: Bool = true
	/// (Optional) Use this parameter if you want to remove the keyboard from specific users only.
  public var selective: Bool = false
	
	
	/**
	Creates a `MarkupKeyboardRemove` instance, to remove an active `MarkupKeyboard` from the current chat.
	
	If isSelective is true, the keyboard will only be removed for the targets of the message.
	
	**Targets:**
	1) users that are @mentioned in the text of the Message object; 
	2) if the bot's message is a reply (has reply_to_message_id), sender of the original message.
	
	- parameter isSelective: If false, the keyboard will be removed for all users.  If true however, the
	keyboard will only be cleared for the targets you specify.
	*/
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

/**
Represents a special action that when sent with a message, will force Telegram clients to display
a reply interface to all or a selected group of people in the chat.
*/
public class MarkupForceReply: NodeConvertible, JSONConvertible, MarkupType {
	
	/// Shows reply interface to the user, as if they manually selected the bot‘s message and tapped ’Reply'
  public var forceReply: Bool = true
	/// (Optional) Use this parameter if you want to force reply from specific users only.
  public var selective: Bool = false
	
	
	
	/**
	Creates a `MarkupForceReply` instance, to force Telegram clients to display
	a reply interface to all or a selected group of people in the chat.
	
	If isSelective is true, the reply interface will only be displayed to targets of the message it is being sent with.
	
	**Targets:**
	1) users that are @mentioned in the text of the Message object;
	2) if the bot's message is a reply (has reply_to_message_id), sender of the original message.
	
	- parameter isSelective: If false, the reply interface will appear for all users.  If true however, the 
	reply interface will only appear for the targets you specify.
	*/
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
