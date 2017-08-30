
import Foundation
import Vapor
import FluentProvider
import JSON

/** 
 Represents a Telegram "Markup Type", that defines additional special actions and interfaces
 alongside a message, such as creating a custom keyboard or forcing a userto reply to the sent 
 message.
 */
public protocol MarkupType: Model {
  
}

public extension MarkupType {
  func getQuery() -> String {
		return try! self.makeRow().converted(to: JSON.self).serialize().makeString()
  }
}


/// Represents a static keyboard interface that when sent, appears below the message entry box on a Telegram client.
final public class MarkupKeyboard: MarkupType {
  public var storage = Storage()
	
  /// An array of keyboard rows, that contain labelled buttons which populate the message keyboard.
  public var keyboard: [[MarkupKeyboardKey]] = []
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
  public required init(row: Row) throws {
    keyboard = try row.get("keyboard")
    resizeKeyboard = try row.get("resize_keyboard")
    oneTimeKeyboard = try row.get("one_time_keyboard")
    selective = try row.get("selective")
  }
  
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("keyboard", keyboard)
		try row.set("resize_keyboard", resizeKeyboard)
		try row.set("one_time_keyboard", oneTimeKeyboard)
		try row.set("selective", selective)
		
		return row
	}
}



/// Represents a single key of a MarkupKeyboard.
final public class MarkupKeyboardKey: Model {
	public var storage = Storage()
	
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
	public init(row: Row) throws {
    text = try row.get("text")
    requestContact = try row.get("request_contact") ?? false
    requestLocation = try row.get("request_location") ?? false
  }
  
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("text", text)
		try row.set("request_contact", requestContact)
		try row.set("request_location", requestLocation)
		
		return row
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
 be received by it in the respective ChatSession, and the prompt will respond based on how you have set 
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
final public class MarkupInline: Model, MarkupType, Equatable {
	public var storage = Storage()
	public var keyboard: [[MarkupInlineKey]] = []
  //public var keyboard: [MarkupInlineRow] = []
  
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
		var array: [MarkupInlineKey] = []
		
    for button in buttonsIn {
      array.append(button)
    }
		
		keyboard.append(array)
  }
  
	/**
	Creates an Inline Keyboard using a series of specified button label and URL string pairs, where all buttons will
	be arranged on a single row.
	- parameter pair: A sequence of label/url String tuples that will define each key on the keyboard.
	*/
  public init(withURL sequence: (url: String, text: String)...) {
    var array: [MarkupInlineKey] = []
		
    for tuple in sequence {
      let button = MarkupInlineKey(fromURL: tuple.url, text: tuple.text)
      array.append(button)
    }
		
    keyboard.append(array)
  }
  
	/**
	Creates an Inline Keyboard using a series of specified button label and callback String pairs, where all buttons will
	be arranged on a single row.
	- parameter pair: A sequence of label/callback String tuples that will define each key on the keyboard.
	*/
  public init?(withCallback sequence: (query: String, text: String?)...) {
    var array: [MarkupInlineKey] = []
		
    for tuple in sequence {
			
			// Try to process them, but propogate the error if it fails.
			guard let button = MarkupInlineKey(fromCallbackData: tuple.query, text: tuple.text) else {
				return nil
			}
			
			array.append(button)
    }
		
    keyboard.append(array)
  }
	
	/**
	Creates an Inline Keyboard using sets of arrays containing label and callback tuples, where each tuple array
	is a single row.
	- parameter array: A an array of label/callback String tuple arrays that will define each row on the keyboard.
	*/
	public init?(withCallback array: [[(query: String, text: String)]]) {
		for row in array {
			var array: [MarkupInlineKey] = []
			for tuple in row {
				
				// Try to process them, but propogate the error if it fails.
				guard let button = MarkupInlineKey(fromCallbackData: tuple.query, text: tuple.text) else {
					return nil
				}
				
				array.append(button)
			}
			keyboard.append(array)
		}
	}
	
	/**
	Creates an Inline Keyboard using a series of specified button label and "Inline Query Current Chat" String pairs, where all buttons will
	be arranged on a single row.
	- parameter pair: A sequence of label/"Inline Query Current Chat" String tuples that will define each key on the keyboard.
	*/
	public init(withInlineQueryCurrent sequence: (query: String, text: String)...) {
		var array: [MarkupInlineKey] = []
		for tuple in sequence {
			let button = MarkupInlineKey(fromInlineQueryCurrent: tuple.query, text: tuple.text)
			array.append(button)
		}
		keyboard.append(array)
	}
	
	/**
	Creates an Inline Keyboard using a series of specified button label and "Inline Query New Chat" String pairs, where all buttons will
	be arranged on a single row.
	- parameter pair: A sequence of label/"Inline Query New Chat" String tuples that will define each key on the keyboard.
	*/
	public init(withInlineQueryNewChat sequence: (query: String, text: String)...) {
		var array: [MarkupInlineKey] = []
		for tuple in sequence {
			let button = MarkupInlineKey(fromInlineQueryNewChat: tuple.query, text: tuple.text)
			array.append(button)
		}
		keyboard.append(array)
	}
	
	/**
	Creates an Inline Keyboard using a series of labels.  The initializer will then generate an associated ID value for each
	label and assign it to the button as Callback data, starting with "1" and incrementing upwards.  
	
	All buttons wil be arranged on a single row.
	
	- parameter labels: A sequence of String labels that will define each key on the keyboard.
	*/
  public init?(withGenCallback sequence: String...) {
    var array: [MarkupInlineKey] = []
    var id = 1
		
    for label in sequence {
			guard let button = MarkupInlineKey(fromCallbackData: String(id), text: label) else {
				return nil
			}
			
      array.append(button)
      id += 1
    }
		
    keyboard.append(array)
  }
  
	/**
	Creates an Inline Keyboard using a set of nested String Arrays, where the array structure defines the specific arrangement
	of the keyboard.
	
	The initializer will generate an associated ID value for eachlabel and assign it to the button as Callback data, starting 
	with "1" and incrementing upwards.
	
	- parameter rows: A nested set of String Arrays, where each String array will form a single row on the inline keyboard.
	*/
  public init?(withGenCallback rows: [[String]]) {
		
    var id = 1
    for row in rows {
      var array: [MarkupInlineKey] = []
			
      for label in row {
				guard let button = MarkupInlineKey(fromCallbackData: String(id), text: label) else {
					return nil
				}
				
        array.append(button)
        id += 1
      }
      keyboard.append(array)
    }
    
  }
	
	/**
	Adds an extra row to the keyboard using the sequence of buttons provided.
	*/
	public func addRow(sequence: MarkupInlineKey...) {
		var array: [MarkupInlineKey] = []
		
		for button in sequence {
			array.append(button)
		}
		
		keyboard.append(array)
	}
	
	/**
	Adds extra rows to the keyboard based on the array of buttons you provide.
	*/
	public func addRow(array: [MarkupInlineKey]...) {
		
		for item in array {
			keyboard.append(item)
		}
	}
  
  
  /**
	Returns all available callback data from any button held inside this markup
	*/
  public func getCallbackData() -> [String]? {
    var data: [String] = []
    for row in keyboard {
      for key in row {
        
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
      for key in row {
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
      for key in row {
        
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
      for key in row {
        
        if key.data == data { return key }
      }
    }
    
    return nil
  }
  
  
  /** 
	Replaces a key with another provided one, by trying to match the given data with a key
   */
  public func replaceKey(usingType type: InlineButtonType, data: String, newKey: MarkupInlineKey) -> Bool {
		
    for (rowIndex, row) in keyboard.enumerated() {
			var newRow = row
			var replaced = false
			
			// Iterate through each key in each row for a match
			for (i, key) in newRow.enumerated() {
				if replaced == true { continue }
				
				if key.type == type {
					if key.data == data {
						newRow.remove(at: i)
						newRow.insert(newKey, at: i)
						replaced = true
					}
				}
			}
			
			// If we made a match, switch out the rows and exit
			if replaced == true {
				keyboard.remove(at: rowIndex)
				keyboard.insert(newRow, at: rowIndex)
				return true
			}
			
    }
    
    return false
  }
  
  /** 
	Replaces a key with another provided one, by trying to match the keys it has with one that's provided.
   */
  public func replaceKey(oldKey: MarkupInlineKey, newKey: MarkupInlineKey) -> Bool {
		
		for (rowIndex, row) in keyboard.enumerated() {
			var newRow = row
			var replaced = false
			
			// Iterate through each key in each row for a match
			for (i, key) in newRow.enumerated() {
				if replaced == true { continue }
				
				if key == oldKey {
					newRow.remove(at: i)
					newRow.insert(newKey, at: i)
					replaced = true
				}
			}
			
			// If we made a match, switch out the rows and exit
			if replaced == true {
				keyboard.remove(at: rowIndex)
				keyboard.insert(newRow, at: rowIndex)
				return true
			}
		}
		
		return false
  }
	
  /** 
	Tries to find and delete a key, based on a match with one provided.
   */
  public func deleteKey(key: MarkupInlineKey) -> Bool {
		
		for (rowIndex, row) in keyboard.enumerated() {
			var newRow = row
			var removed = false
			
			// Iterate through each key in each row for a match
			for (i, newKey) in newRow.enumerated() {
				if removed == true { continue }
				
				if key == newKey {
					newRow.remove(at: i)
					removed = true
				}
			}
			
			// If we made a match, switch out the rows and exit
			if removed == true {
				keyboard.remove(at: rowIndex)
				keyboard.insert(newRow, at: rowIndex)
				return true
			}
		}
		
		return false
  }
	
	static public func ==(lhs: MarkupInline, rhs: MarkupInline) -> Bool {
		
		if lhs.keyboard.count != rhs.keyboard.count { return false }
		
		for (i, lhsRow) in lhs.keyboard.enumerated() {
			
			let rhsRow = rhs.keyboard[i]
			if lhsRow.count != rhsRow.count { return false }
			
			for (iKey, lhsKey) in lhsRow.enumerated() {
				
				let rhsKey = rhsRow[iKey]
				if lhsKey != rhsKey { return false }
			}
		}
		
		return true
	}
  
	
  public required init(row: Row) throws {
    keyboard = try row.get("inline_keyboard")
  }
  
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("inline_keyboard", keyboard)
		
		return row
	}
  
  
}


/**
Defines a single keyboard key on a `MarkupInline` keyboard.  Each key supports one of 4 different modes:
_ _ _ _ _

**Callback Data**

This sends a small String back to the bot as a `CallbackQuery`, which is automatically filtered
back to the session and to a `callbackState` if one exists.

Alternatively if the keyboard the button belongs to is part of a `Prompt`, it will automatically
be received by it in the respective ChatSession, and the prompt will respond based on how you have set
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
final public class MarkupInlineKey: Model, Equatable {
	public var storage = Storage()
	
  public var text: String // Label text
  public var data: String
  public var type: InlineButtonType
  
	
	/** 
	Creates a `MarkupInlineKey` as a URL key.
	
	This key type causes the specified URL to be opened by the client
	when button is pressed.  If it links to a public Telegram chat or bot, it will be immediately opened.
	*/
  public init(fromURL url: String, text: String) {
    self.text = text
    self.data = url
    self.type = .url
  }
	
	/**
	Creates a `MarkupInlineKey` as a Callback Data key.
	
	This key sends the defined callback data back to the bot to be handled.
	
	- parameter callback: The data to be sent back to the bot once pressed.  Accepts 1-64 bytes of data.
	- parameter text: The text label to be shown on the button.  Set to nil if you wish it to be the same as the callback.
	*/
  public init?(fromCallbackData callback: String, text: String?) {
		
		// Check to see if the callback meets the byte requirement.
		if callback.lengthOfBytes(using: String.Encoding.utf8) > 64 {
			PLog.error("The MarkupKey with the text label, \"\(String(describing:text))\" has a callback of \(callback) that exceeded 64 bytes.")
			return nil
		}
		
		// Check to see if we have a label
		if text != nil { self.text = text! }
		else { self.text = callback }
		
    self.data = callback
    self.type = .callbackData
  }
	
	/**
	Creates a `MarkupInlineKey` as a Current Chat Inline Query key.
	
	This key prompts the user to select one of their chats, open it and insert the bot‘s username and the specified query in the input field.
	*/
  public init(fromInlineQueryCurrent data: String, text: String) {
    self.text = text
    self.data = data
    self.type = .switchInlineQuery_currentChat
  }
	
	/**
	Creates a `MarkupInlineKey` as a New Chat Inline Query key.
	
	This key inserts the bot‘s username and the specified inline query in the current chat's input field.  Can be empty.
	*/
	public init(fromInlineQueryNewChat data: String, text: String) {
		self.text = text
		self.data = data
		self.type = .switchInlineQuery
	}
	
	static public func ==(lhs: MarkupInlineKey, rhs: MarkupInlineKey) -> Bool {
		
		if lhs.text != rhs.text { return false }
		if lhs.type != rhs.type { return false }
		if lhs.data != rhs.data { return false }
		
		return true
	}
	
  // Ignore context, just try and build an object from a node.
  public required init(row: Row) throws {
    text = try row.get("text")
		
		if row["url"] != nil {
			data = try row.get("url")
			type = .url
		}
		
		else if row["callback_data"] != nil {
			data = try row.get("callback_data")
			type = .url
		}
		
		else if row["switch_inline_query"] != nil {
			data = try row.get("switch_inline_query")
			type = .url
		}
		
		else if row["switch_inline_query_current_chat"] != nil {
			data = try row.get("switch_inline_query_current_chat")
			type = .url
		}
		
		else {
			data = ""
			type = .url
		}
  }
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("text", text)
		
		switch type {
		case .url:
			try row.set("url", data)
		case .callbackData:
			try row.set("callback_data", data)
		case .switchInlineQuery:
			try row.set("switch_inline_query", data)
		case .switchInlineQuery_currentChat:
			try row.set("switch_inline_query_current_chat", data)
		}
		
		return row
	}
}

/**
Defines what type of function a InlineButtonKey has.
*/
public enum InlineButtonType: String {
  /// HTTP url to be opened by the client when button is pressed.
  case url
	/// Data to be sent in a callback query to the bot when button is pressed, 1-64 bytes
  case callbackData
	/// Prompts the user to select one of their chats, open it and insert the bot‘s username and the specified query in the input field.
  case switchInlineQuery
	/// If set, pressing the button will insert the bot‘s username and the specified inline query in the current chat's input field.  Can be empty.
  case switchInlineQuery_currentChat
}


/**
Represents a special action that when sent with a message, will remove any `MarkupKeyboard` 
currently active, for either all of or a specified group of users.
*/
final public class MarkupKeyboardRemove: Model, MarkupType {
	public var storage = Storage()
	
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
  public required init(row: Row) throws {
    removeKeyboard = try row.get("remove_keyboard")
    selective = try row.get("selective")
    
  }
  
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("remove_keyboard", removeKeyboard)
		try row.set("selective", selective)
		
		return row
	}
  
}

/**
Represents a special action that when sent with a message, will force Telegram clients to display
a reply interface to all or a selected group of people in the chat.
*/
final public class MarkupForceReply: Model, MarkupType {
	public var storage = Storage()
	
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
  public required init(row: Row) throws {
    forceReply = try row.get("force_reply")
    selective = try row.get("selective")
    
  }
  
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("force_reply", forceReply)
		try row.set("selective", selective)
		
		return row
	}
}
