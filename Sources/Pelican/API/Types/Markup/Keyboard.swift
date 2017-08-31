//
//  Keyboard.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

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
